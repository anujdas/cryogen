require "yaml"

require "./key"
require "./crypto"

module Cryogen
  struct VaultEntry
    alias Namespace = String
    alias Secret = String
    alias ValueType = Hash(Namespace, self | Secret)

    def self.empty : self
      new(ValueType.new)
    end

    ###

    delegate to_yaml, to: @value

    def initialize(@value : ValueType)
    end

    def decrypt(key : Key) : self
      hash = @value.each_with_object(ValueType.new) do |(prefix, val), h|
        h[prefix] = val.is_a?(Secret) ? Crypto.verify_and_decrypt(val, key) : val.decrypt(key)
      end
      self.class.new(hash)
    end

    def encrypt(key : Key) : self
      hash = @value.each_with_object(ValueType.new) do |(prefix, val), h|
        h[prefix] = val.is_a?(Secret) ? Crypto.encrypt_and_sign(val, key) : val.encrypt(key)
      end
      self.class.new(hash)
    end

    def to_env(namespace : String? = nil) : Hash(String, String)
      @value.each_with_object({} of String => String) do |(name, val), vars|
        full_name = [namespace, name].compact.join("_")
        vars.merge!(val.is_a?(Secret) ? { full_name.upcase => val } : val.to_env(full_name))
      end
    end

    ### YAML parsing helpers (providing detailed format validation)

    def self.new(ctx : YAML::ParseContext, node : YAML::Nodes::Node)
      ctx.read_alias(node, self) { |obj| return obj }
      hash = ValueType.new
      ctx.record_anchor(node, hash)
      new(ctx, node) do |identifier, value|
        node.raise "Duplicate mapping for #{identifier} found" if hash.has_key?(identifier)
        hash[identifier] = value
      end
      new(hash)
    end

    def self.new(ctx : YAML::ParseContext, node : YAML::Nodes::Node)
      node.raise "Expected mapping, not #{node.class}" unless node.is_a?(YAML::Nodes::Mapping)
      YAML::Schema::Core.each(node) do |key, value|
        value_class = value.is_a?(YAML::Nodes::Mapping) ? self : Secret
        yield Namespace.new(ctx, key), value_class.new(ctx, value)
      end
    end
  end
end
