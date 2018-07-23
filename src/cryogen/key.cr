require "base64"
require "file"
require "random/secure"

require "./error"

module Cryogen
  class Key
    CIPHER_KEY_BYTES = 32 # == 256 bits for AES-256-CBC (which is overkill)
    SIGNING_KEY_BYTES = 32 # == 256 bits for HMAC-SHA256 (which is also overkill)
    KEY_BYTES = CIPHER_KEY_BYTES + SIGNING_KEY_BYTES

    def self.generate : self
      key_material = Bytes.new(KEY_BYTES)
      Random::Secure.random_bytes(key_material)
      new(key_material)
    end

    def self.from_base64(stringified_key : String) : self
      new(Base64.decode(stringified_key))
    end

    def self.load(key_file : String) : self
      key_material = Bytes.new(KEY_BYTES)
      File.open(key_file, "rb") { |f| f.read(key_material) }
      new(key_material)
    end

    ###

    getter cipher_key : Bytes, signing_key : Bytes

    def initialize(key_material : Bytes)
      raise Error::KeyInvalid.new unless key_material.size == KEY_BYTES
      @cipher_key = key_material[0, CIPHER_KEY_BYTES]
      @signing_key = key_material[CIPHER_KEY_BYTES, SIGNING_KEY_BYTES]
    end

    def to_base64 : String
      io = IO::Memory.new.tap do |io|
        io.write(@cipher_key)
        io.write(@signing_key)
      end
      Base64.strict_encode(io)
    end

    def save!(key_file : String)
      File.open(key_file, "wb") do |f|
        f.write(@cipher_key)
        f.write(@signing_key)
      end
    end
  end
end
