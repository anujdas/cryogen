require "yaml"

require "./key"
require "./crypto"

module Cryogen
  # TODO: make this a generic struct and implement Encrypted/DecryptedEntry
  # as Entry(T) once crystal adds support for generic aliases; see
  # https://github.com/crystal-lang/crystal/issues/5155
  struct VaultEntry
    alias Namespace = String
    alias Secret = String
    alias ValueType = Hash(Namespace, self | Secret)

    # provide iterator/enumerator methods delegated to enclosed value
    include Iterable({Namespace, self | Secret})
    include Enumerable({Namespace, self | Secret})

    def self.empty : self
      new(ValueType.new)
    end

    ###

    delegate each, to_yaml, to: @value

    def initialize(@value : ValueType)
    end

    def decrypt(key : Key) : self
      hash = each_with_object(ValueType.new) do |(prefix, val), h|
        h[prefix] = val.is_a?(Secret) ? Crypto.verify_and_decrypt(val, key) : val.decrypt(key)
      end
      self.class.new(hash)
    end

    def encrypt(key : Key) : self
      hash = each_with_object(ValueType.new) do |(prefix, val), h|
        h[prefix] = val.is_a?(Secret) ? Crypto.encrypt_and_sign(val, key) : val.encrypt(key)
      end
      self.class.new(hash)
    end

    # assuming an encrypted entry, return a new entry containing contents of
    # another encrypted entry, but with the ciphertext of this entry if
    # plaintext matches. this prevents ciphertext churn for plaintext no-ops.
    def merge_encrypted(other : self, key : Key) : self
      merged_hash = other.each_with_object(ValueType.new) do |(k, other_enc_v), h|
        this_enc_v = @value[k]?  # fetch current value for comparison
        if this_enc_v.is_a?(self) && other_enc_v.is_a?(self)  # both this and other are Entries
          h[k] = this_enc_v.merge_encrypted(other_enc_v, key)  # deep merge
        elsif this_enc_v.is_a?(Secret) && other_enc_v.is_a?(Secret)  # both this and other are Secrets
          if Crypto.verify_and_decrypt(this_enc_v, key) != Crypto.verify_and_decrypt(other_enc_v, key)
            h[k] = other_enc_v  # plaintext changed; replace ciphertext
          else
            h[k] = this_enc_v  # same plaintext; keep current ciphertext
          end
        else  # no current value or type changed
          h[k] = other_enc_v  # use new value
        end
      end
      self.class.new(merged_hash)
    end

    def to_env(namespace : String? = nil) : Hash(String, String)
      each_with_object({} of String => String) do |(name, val), vars|
        full_name = [namespace, name].compact.join("_")
        vars.merge!(val.is_a?(Secret) ? {full_name.upcase => val} : val.to_env(full_name))
      end
    end

    # YAML parsing helpers (providing detailed format validation)

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
