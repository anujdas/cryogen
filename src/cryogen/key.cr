require "file"
require "openssl_ext"

require "./errors"

module Cryogen
  class Key
    DEFAULT_BITS = 4_096
    PEM_PASSWORD_CIPHER = OpenSSL::Cipher.new("AES-256-CBC")

    def self.generate(key_bits : Integer = DEFAULT_BITS)
      new(OpenSSL::RSA.generate(key_bits))
    end

    def self.from_file(key_file : String)
      new(OpenSSL::PKey::RSA.new(File.read(key_file)))
    rescue OpenSSL::PKey::RSAError
      raise Errors::DecryptionError, "Invalid PEM file #{key_file}"
    end

    def self.from_protected_file(key_file, password)
      new(OpenSSL::PKey::RSA.new(File.read(key_file), password))
    rescue OpenSSL::PKey::RSAError
      raise Errors::DecryptionError,
        "Either the password is invalid or the key file #{key_file} is corrupted"
    end

    ###

    def initialize(key)
      @key = key
    end

    def save(key_file : String, password : String = nil)
      pem =
        if password
          @key.to_pem(PEM_PASSWORD_CIPHER, password)
        else
          @key.to_pem
        end

      File.open(key_file, 'w') { |f| f.write(pem) }
    end

    def encrypt(plaintext)
      @key.public_encrypt(plaintext)
    end

    def decrypt(ciphertext)
      @key.private_decrypt(ciphertext)
    end
  end
end
