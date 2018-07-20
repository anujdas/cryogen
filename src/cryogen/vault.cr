require "file"
require "yaml"

require "./crypto"

module Cryogen
  alias Prefix = String
  alias Value = String

  record Entry, contents : Hash(Prefix, Entry | Value) do
    def self.from_yaml(string_or_io) : self
      parse_yaml(YAML.parse(string_or_io))
    end

    delegate to_yaml, to: contents

    def decrypt(key : Key) : self
      hash = contents.each_with_object({} of Prefix => Entry | Value) do |(prefix, val), h|
        h[prefix] = val.is_a?(Entry) ? val.decrypt(key) : Crypto.verify_and_decrypt(val, key)
      end
      self.class.new(hash)
    end

    def encrypt(key : Key) : self
      hash = contents.each_with_object({} of Prefix => Entry | Value) do |(prefix, val), h|
        h[prefix] = val.is_a?(Entry) ? val.encrypt(key) : Crypto.encrypt_and_sign(val, key)
      end
      self.class.new(hash)
    end

    def to_env(outer_prefix : String? = nil) : Hash(String, String)
      contents.each_with_object({} of String => String) do |(inner_prefix, val), vars|
        prefix = [outer_prefix, inner_prefix].compact.join("_")
        vars.merge!(val.is_a?(Entry) ? val.to_env(prefix) : { prefix.upcase => val })
      end
    end

    private def self.parse_yaml(yaml : YAML::Any) : self
      hash = yaml.as_h.each_with_object({} of Prefix => Entry | Value) do |(key, val), h|
        h[key.as_s] = val.as_h? ? parse_yaml(val) : val.as_s
      end
      new(hash)
    end
  end

  class LockedVault
    delegate to_yaml, to: @contents

    def self.load(vault_file : String) : self
      File.open(vault_file, "r") { |f| new(Entry.from_yaml(f)) }
    end

    def initialize(@contents = Entry.new({} of Prefix => Entry | Value))
    end

    def unlock!(key : Key) : UnlockedVault
      UnlockedVault.new(@contents.decrypt(key))
    end

    def save!(vault_file : String)
      File.open(vault_file, "w") { |f| to_yaml(f) }
    end
  end

  class UnlockedVault
    delegate to_yaml, to_env, to: @contents

    def self.load(vault_file : String) : self
      File.open(vault_file, "r") { |f| new(Entry.from_yaml(f)) }
    end

    def initialize(@contents = Entry.new({} of Prefix => Entry | Value))
    end

    def lock!(key : Key) : LockedVault
      LockedVault.new(@contents.encrypt(key))
    end

    def save!(vault_file : String)
      File.open(vault_file, "w") { |f| to_yaml(f) }
    end
  end
end
