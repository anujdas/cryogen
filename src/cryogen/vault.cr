require "file"
require "yaml"

require "./crypto"
require "./error"

module Cryogen
  abstract struct Vault
    struct Entry
      alias Identifier = String
      alias Value = String

      def self.from_yaml(string_or_io) : self
        parse_yaml(YAML.parse(string_or_io))
      end

      def self.empty : self
        new({} of Identifier => self | Value)
      end

      delegate to_yaml, to: @value

      def initialize(@value : Hash(Identifier, Entry | Value))
      end

      def decrypt(key : Key) : self
        hash = @value.each_with_object({} of Identifier => Entry | Value) do |(prefix, val), h|
          h[prefix] = val.is_a?(Entry) ? val.decrypt(key) : Crypto.verify_and_decrypt(val, key)
        end
        self.class.new(hash)
      end

      def encrypt(key : Key) : self
        hash = @value.each_with_object({} of Identifier => Entry | Value) do |(prefix, val), h|
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

      private def self.parse_yaml(yaml : YAML::Any) : self
        raise Error::VaultInvalid.new unless yaml.as_h?
        hash = yaml.as_h.each_with_object({} of Identifier => Entry | Value) do |(key, val), h|
          raise Error::VaultInvalid.new unless key.as_s?
          h[key.as_s] = if val.as_h?
                          parse_yaml(val)
                        elsif val.as_s?
                          val.as_s
                        else
                          raise Error::VaultInvalid.new
                        end
        end
        new(hash)
      end
    end

    delegate to_yaml, to: @contents

    def self.load(vault_file : String) : self
      File.open(vault_file, "r") { |f| new(Entry.from_yaml(f)) }
    end

    def initialize(@contents = Entry.empty)
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
