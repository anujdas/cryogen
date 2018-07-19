require "file"
require "yaml"

require "./crypto"

module Cryogen
  class Chest
    record EncryptedEntry, value : Nil | String | Hash(String, EncryptedEntry)
    record Entry, value : Nil | String | Hash(String, Entry)

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
      hash = yaml_hash.each_with_object({} of String => EncryptedEntry) do |(key, val), h|
        h[key.as_s] = val.as_h? ? parse_yaml(val.as_h) : EncryptedEntry.new(val.as_s)
      end

      EncryptedEntry.new(hash)
    end

    private def decrypt(encrypted_entry : EncryptedEntry) : Entry
      decrypted_value = 
        case value = encrypted_entry.value
        when String
          Crypto.verify_and_decrypt(value, @key)
        when Hash
          value.each_with_object({} of String => Entry) { |(key, val), h| h[key] = decrypt(val) }
        end

      Entry.new(decrypted_value)
    end

    private def encrypt(decrypted_entry : Entry) : EncryptedEntry
      encrypted_value = 
        case value = decrypted_entry.value
        when String
          Crypto.encrypt_and_sign(value, @key)
        when Hash
          value.each_with_object({} of String => EncryptedEntry) do |(key, val), h|
            h[key] = encrypt(val)
          end
        end

      EncryptedEntry.new(encrypted_value)
    end
  end
end
