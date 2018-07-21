require "crypto/bcrypt/password"
require "file"
require "openssl"

require "./error"

module Cryogen
  class Key
    KEY_BYTES = 32 # bytes == 256 bits for each of cipher and signing

    # uses bcrypt to stretch password, then hashes that into 512 bits of key data
    def self.from_password(password : String) : Key
      derived_key = ::Crypto::Bcrypt::Password.create(password).digest
      digest = OpenSSL::Digest.new("SHA512") # we'll need 256 + 256 bits
      digest.update(derived_key)
      new(digest.digest)
    end

    def self.load(key_file : String) : Key
      slice = Bytes.new(KEY_BYTES * 2)
      File.open(key_file, "rb") { |f| f.read(slice) }
      new(slice)
    end

    ###

    getter cipher_key : Bytes, signing_key : Bytes

    # Given a 512-bit key, splits it into a 256-bit encryption key and a
    # 256-bit signing key
    def initialize(key_material : Bytes)
      raise Error::KeyInvalid.new unless key_material.size == KEY_BYTES * 2
      @cipher_key = key_material[0, KEY_BYTES]
      @signing_key = key_material[KEY_BYTES, KEY_BYTES]
    end

    def save!(key_file : String)
      File.open(key_file, "wb") do |f|
        f.write(@cipher_key)
        f.write(@signing_key)
      end
    end
  end
end
