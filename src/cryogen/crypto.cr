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
      # set up cipher in encrypt mode using weird openssl-isms
      cipher = OpenSSL::Cipher.new(CIPHER_MODE)
      cipher.encrypt
      cipher.key = key.cipher_key
      iv = cipher.random_iv # let OpenSSL pick a random initialisation vector

      # encrypt using 256-bit AES CBC
      data = concat_bytes(cipher.update(value.to_slice), cipher.final)

      # sign (iv + data) using SHA256-HMAC
      sig = OpenSSL::HMAC.digest(SIG_MODE, key.signing_key, concat_bytes(iv, data))

      # return "iv$data$sig"
      [iv, data, sig].map { |s| Base64.strict_encode(s) }.join(SEPARATOR)
    end

    def self.verify_and_decrypt(encrypted_value : String, key : Key) : String
      # parse "iv$data$sig"
      iv, data, sig = encrypted_value.split(SEPARATOR).map { |s| Base64.decode(s) }
        
      # verify HMAC-256 before decoding
      calculated_sig = OpenSSL::HMAC.digest(SIG_MODE, key.signing_key, concat_bytes(iv, data))
      raise Error::SignatureInvalid.new unless calculated_sig == sig

      # set up cipher in decrypt mode using weird openssl-isms
      cipher = OpenSSL::Cipher.new(CIPHER_MODE)
      cipher.decrypt
      cipher.key = key.cipher_key
      cipher.iv = iv

      # decode using AES-256-CBC
      String.new(concat_bytes(cipher.update(data), cipher.final))
    rescue e : OpenSSL::Cipher::Error
      raise Error::DecryptionError.new(e)
    end

    private def self.concat_bytes(*bytestrings : Bytes) : Bytes
      io = IO::Memory.new
      bytestrings.each { |bs| io.write(bs) }
      io.to_slice
    end
  end
end
