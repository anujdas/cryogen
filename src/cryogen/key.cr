require "crypto/bcrypt/password"
require "file"
require "openssl"

module Cryogen
  class Key
    @cipher_key : Bytes
    @signing_key : Bytes

    getter :cipher_key, :signing_key

    # uses bcrypt to stretch password, then hashes that into 512 bits of key data
    def self.from_password(password : String) : Key
      derived_key = ::Crypto::Bcrypt::Password.create(password).digest
      digest = OpenSSL::Digest.new("SHA512") # we'll need 256 + 256 bits
      digest.update(derived_key)
      new(digest.digest)
    end

    def self.load(key_file : String) : Key
      slice = Bytes.new(64)
      File.open(key_file, "r") { |f| f.read(slice) }
      new(slice)
    end

    # Given a 512-bit key, splits it into a 256-bit encryption key and a
    # 256-bit signing key
    def initialize(key_material : Bytes)
      raise "Key must be 512 bits" unless key_material.size == 64 # bytes
      @cipher_key = key_material[0, 32]
      @signing_key = key_material[16, 32]
    end

    def save!(key_file : String)
      File.open(key_file, "w") do |f|
        f.write(@cipher_key)
        f.write(@signing_key)
      end
    end
  end
end
