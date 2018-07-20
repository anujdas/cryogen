require "base64"
require "openssl/cipher"
require "openssl/hmac"

require "./error"
require "./key"

module Cryogen
  module Crypto
    CIPHER_MODE = "AES-256-CBC"
    SIG_MODE = :sha256
    SEPARATOR = '$'

    def self.encrypt_and_sign(value : String, key : Key) : String
      # encrypt using 256-bit AES CBC
      cipher = OpenSSL::Cipher.new(CIPHER_MODE)
      cipher.encrypt
      cipher.key = key.cipher_key
      iv = cipher.random_iv.to_s
      io = IO::Memory.new
      io.write(cipher.update(value))
      io.write(cipher.final)
      data = io.to_slice.hexstring

      # sign (iv + data) using SHA256-HMAC
      sig = OpenSSL::HMAC.digest(SIG_MODE, key.signing_key, iv + data)

      # return "iv$data$sig"
      [iv, data, sig].map { |s| Base64.strict_encode(s) }.join(SEPARATOR)
    end

    def self.verify_and_decrypt(encrypted_value : String, key : Key) : String
      # parse "iv$data$sig"
      iv, encrypted_string, sig = encrypted_value.
        split(SEPARATOR).map { |s| Base64.decode_string(s) }

      # verify HMAC-256 before decoding
      calculated_sig = OpenSSL::HMAC.digest(SIG_MODE, key.signing_key, iv + encrypted_string)
      raise Error::SignatureInvalid.new unless calculated_sig == sig

      # decode using AES-256-CBC
      cipher = OpenSSL::Cipher.new(CIPHER_MODE)
      cipher.decrypt
      cipher.key = key.cipher_key
      cipher.iv = iv
      IO::Memory.new.tap do |io|
        io.write(cipher.update(encrypted_string))
        io.write(cipher.final)
      end.to_s
    rescue e : OpenSSL::Cipher::Error
      raise Error::DecryptionError.new(e)
    end
  end
end
