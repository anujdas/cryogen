require "file"
require "yaml"

require "./crypto"

module Cryogen
  class Chest
    alias ChestObject = String | Hash(String, ChestObject)
    alias ChestDocument = Hash(String, ChestObject)

    class Entry
      def initialize(@value : ChestObject, @prefix : String = "")
      end

      def decrypt(key : Key) : Entry
        encrypted_value = @value
        decrypted_value =
          if encrypted_value.is_a?(Hash)
            encrypted_value.
              each_with_object({} of String => Entry) do |(nested_prefix, encrypted_entry), h|
                h[nested_prefix] = Entry.new(encrypted_entry, nested_prefix).decrypt(key)
              end
          else
            Crypto.verify_and_decrypt(encrypted_value, key)
          end

        Entry.new(decrypted_value, @prefix)
      end

      def encrypt(key : Key) : Entry
        decrypted_value = @value # apparently the typechecker needs this
        encrypted_value =
          if decrypted_value.is_a?(Hash)
            decrypted_value.
              each_with_object({} of String => Entry) do |(nested_prefix, entry), h|
                h[nested_prefix] = Entry.new(entry, nested_prefix).encrypt(key)
              end
          else
            Crypto.encrypt_and_sign(decrypted_value, key)
          end

        Entry.new(encrypted_value, @prefix)
      end
    end

    def initialize(@chest_file : String, @key : Key)
    end

    def decrypted_contents : ChestDocument
      Entry.new(read_raw_contents).decrypt(@key)
    end

    def update_contents(new_contents : ChestDocument)
      raw_contents = Entry.new(new_contents).encrypt(@key)
      write_raw_contents(new_contents)
    end

    private def parse_yaml(yaml_hash) : ChestObject
      yaml_hash.each_with_object({} of String => ChestObject) do |(key, val), h|
        h[key.as_s] = val.as_s? ? val.as_s : parse_yaml(val.as_h)
      end
    end

    private def read_raw_contents : ChestDocument
      raw_contents = File.open(@chest_file, "r") { |f| YAML.parse(f) }
      parse_yaml(raw_contents.as_h).as(ChestDocument)
    end

    private def write_raw_contents(raw_contents : ChestDocument)
      File.open(@chest_file, "w") { |f| YAML.dump(raw_contents, f) }
    end
  end
end
