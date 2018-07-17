require "crypto/bcrypt/password"
require "file"
require "openssl"

module Cryogen
  class Key
    @cipher_key : String
    @signing_key : String

    getter :cipher_key, :signing_key

    # uses bcrypt to stretch password, then hashes that into 512 bits of key data
    def self.from_password(password : String) : Key
      derived_key = ::Crypto::Bcrypt::Password.create(password).digest
      digest = OpenSSL::Digest.new("SHA512") # we'll need 256 + 256 bits
      digest.update(derived_key)
      new(digest.digest.to_s)
    end

    def self.from_file(key_file : String) : Key
      new(File.read(key_file))
    end

    # Given a 512-bit key, splits it into a 256-bit encryption key and a
    # 256-bit signing key
    def initialize(key_material : String)
      raise "Key must be 512 bits" unless key_material.size == 64 # bytes
      @cipher_key = key_material[0, 32]
      @signing_key = key_material[16, 32]
    end
  end
end
