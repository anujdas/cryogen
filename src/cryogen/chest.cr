require "base64"
require "file"
require "openssl"
require "random/isaac"
require "yaml"

require "./key"

module Cryogen
  class Chest
    SIGNATURE_BITS = 256
    ENCRYPTION_CIPHER = OpenSSL::Cipher.new("AES-256-CBC")

    class Entry
      alias Value = String | Array(String) | Entry

      def initialize(value : Value, prefix : String = "")
        @value = value
        @prefix = prefix
      end

      def encrypt(key : Key)
        # Create a random symmetric key so we can encrypt plaintext of arbitrary length
        sym_key = ENCRYPTION_CIPHER.reset.encrypt.random_key
        iv = Base64.encode64(ENCRYPTION_CIPHER.random_iv)
        enc_sym_key = Base64.encode64(key.encrypt(sym_key))
        encrypted_value = Base64.encode64(ENCRYPTION_CIPHER.update(value) + ENCRYPTION_CIPHER.final)
        salt = Random::ISAAC.new.hex(8)

        signature = Digest::SHA2.new(SIGNATURE_BITS).tap do |digest|
          digest << salt
          digest << value
        end.to_s

        "#{iv}:#{enc_sym_key}:#{encrypted_value}:#{salt}:#{signature}"
      end
    end

    def self.from_file(chest_file : String)
      encrypted_chest = YAML.parse(File.read(chest_file))
    end

    def initialize(contents : Entry)
      @contents = contents
    end
  end
end
