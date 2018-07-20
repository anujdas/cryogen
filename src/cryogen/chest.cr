require "file"
require "yaml"

require "./crypto"

module Cryogen
  class Chest
    alias Prefix = String
    alias Value = String
    alias EncryptedValue = String

    record Entry, value : Hash(Prefix, Entry | Value) do
      def to_yaml(io)
        value.to_yaml(io)
      end
    end

    record EncryptedEntry, value : Hash(Prefix, EncryptedEntry | EncryptedValue) do
      def to_yaml(io)
        value.to_yaml(io)
      end
    end

    def self.blank_contents : Entry
      Entry.new({} of Prefix => Entry | Value)
    end

    def initialize(@chest_file : String, @key : Key)
    end

    def decrypted_contents : Entry
      decrypt(read_raw_contents)
    end

    def update_contents!(new_contents : Entry)
      write_raw_contents(encrypt(new_contents))
    end

    private def read_raw_contents : EncryptedEntry
      raw_contents = File.open(@chest_file, "r") { |f| YAML.parse(f) }
      parse_yaml(raw_contents.as_h)
    end

    private def write_raw_contents(raw_contents : EncryptedEntry)
      File.open(@chest_file, "w") { |f| YAML.dump(raw_contents, f) }
    end

    private def parse_yaml(yaml_hash : Hash) : EncryptedEntry
      hash = yaml_hash.each_with_object({} of Prefix => EncryptedEntry | EncryptedValue) do |(key, val), h|
        h[key.as_s] = val.as_h? ? parse_yaml(val.as_h) : val.as_s
      end

      EncryptedEntry.new(hash)
    end

    private def encrypt(decrypted_entry : Entry) : EncryptedEntry
      hash = decrypted_entry.value.
        each_with_object({} of Prefix => EncryptedEntry | EncryptedValue) do |(key, val), h|
          h[key] = val.is_a?(Entry) ? encrypt(val) : Crypto.encrypt_and_sign(val, @key)
        end

      EncryptedEntry.new(hash)
    end

    private def decrypt(encrypted_entry : EncryptedEntry) : Entry
      hash = encrypted_entry.value.each_with_object({} of Prefix => Entry | Value) do |(key, val), h|
        h[key] = val.is_a?(EncryptedEntry) ? decrypt(val) : Crypto.verify_and_decrypt(val, @key)
      end

      Entry.new(hash)
    end
  end
end
