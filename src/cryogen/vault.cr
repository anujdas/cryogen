require "file"
require "yaml"

require "./crypto"
require "./error"

module Cryogen
  abstract struct Vault
    struct Entry
      alias Identifier = String
      alias Secret = String
      alias ValueType = Hash(Identifier, self | Secret)

      def self.empty : self
        new(ValueType.new)
      end

      delegate to_yaml, to: @value

      def initialize(@value : ValueType)
      end

      def decrypt(key : Key) : self
        hash = @value.each_with_object(ValueType.new) do |(prefix, val), h|
          h[prefix] = val.is_a?(Entry) ? val.decrypt(key) : Crypto.verify_and_decrypt(val, key)
        end
        self.class.new(hash)
      end

      def encrypt(key : Key) : self
        hash = @value.each_with_object(ValueType.new) do |(prefix, val), h|
          h[prefix] = val.is_a?(Entry) ? val.encrypt(key) : Crypto.encrypt_and_sign(val, key)
        end
        self.class.new(hash)
      end

      def to_env(prefix : String? = nil) : Hash(String, String)
        @value.each_with_object({} of String => String) do |(identifier, val), vars|
          qualified_id = [prefix, identifier].compact.join("_")
          vars.merge!(val.is_a?(Entry) ? val.to_env(qualified_id) : { qualified_id.upcase => val })
        end
      end

      ### YAML parsing helpers (providing detailed format validation)

      def self.new(ctx : YAML::ParseContext, node : YAML::Nodes::Node)
        ctx.read_alias(node, self) { |obj| return obj }
        hash = ValueType.new
        ctx.record_anchor(node, hash)
        new(ctx, node) { |identifer, value| hash[identifer] = value }
        new(hash)
      end

      def self.new(ctx : YAML::ParseContext, node : YAML::Nodes::Node)
        node.raise "Expected mapping, not #{node.class}" unless node.is_a?(YAML::Nodes::Mapping)
        YAML::Schema::Core.each(node) do |key, value|
          value_class = value.is_a?(YAML::Nodes::Mapping) ? self : Secret
          yield Identifier.new(ctx, key), value_class.new(ctx, value)
        end
      end
    end

    delegate to_yaml, to: @contents

    def self.load(vault_file : String) : self
      File.open(vault_file, "r") { |f| new(Entry.from_yaml(f)) }
    end

    def initialize(@contents : Entry = Entry.empty)
    end

    def save!(vault_file : String)
      File.open(vault_file, "w") { |f| to_yaml(f) }
    end
  end

  struct LockedVault < Vault
    def unlock!(key : Key) : UnlockedVault
      UnlockedVault.new(@contents.decrypt(key))
    end
  end

  struct UnlockedVault < Vault
    delegate to_env, to: @contents

    def lock!(key : Key) : LockedVault
      LockedVault.new(@contents.encrypt(key))
    end
  end
end
