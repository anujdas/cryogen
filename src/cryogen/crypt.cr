require "openssl"

module Cryogen
  module Crypt
    SIGNATURE_SIZE_BITS = 256
    ENCRYPTION_CIPHER = OpenSSL::Cipher.new("AES-256-CBC")

    def process_hash_changes(original_encrypted, original_decrypted, current)
      result = {}

      current.keys.each do |key|
        value = current[key]

        result[key] =
          if original_encrypted.key?(key)
            # Key still exists; check if modified.
            if value.is_a?(Hash)
              if original_encrypted[key].is_a?(Hash)
                process_hash_changes(original_encrypted[key], original_decrypted[key], value)
              else
                # Key changed from single value to hash, so no previous has to compare against
                process_hash_changes({}, {}, value)
              end
            elsif original_decrypted[key] != value
              # Value was changed; encrypt the new value
              encrypt_value(value)
            else
              # Value wasn't changed; keep original encrypted blob
              original_encrypted[key]
            end
          else
            # Key was added
            value.is_a?(Hash) ? process_hash_changes({}, {}, value) : encrypt_value(value)
          end
      end

      result
    end

    def decrypt_hash(hash)
      hash.each_with_object({}) do |(key, value), decrypted_hash|
        begin
          decrypted_hash[key] = value.is_a?(Hash) ? decrypt_hash(value) : decrypt_value(value)
        rescue Errors::DecryptionError => ex
          raise Errors::DecryptionError,
            "Problem decrypting value for key '#{key}': #{ex.message}"
        end
      end
    end

    def encrypt_value(value)
      # Create a random symmetric key so we can encrypt plaintext of arbitrary length
      sym_key = ENCRYPTION_CIPHER.reset.encrypt.random_key
      iv = Base64.encode64(ENCRYPTION_CIPHER.random_iv)
      enc_sym_key = Base64.encode64(@key.encrypt(sym_key))
      encrypted_value = Base64.encode64(ENCRYPTION_CIPHER.update(value) +
                                        ENCRYPTION_CIPHER.final)

      salt = SecureRandom.hex(8)

      signature = Digest::SHA2.new(SIGNATURE_SIZE_BITS).tap do |digest|
        digest << salt
        digest << value
      end.to_s

      "#{iv}:#{enc_sym_key}:#{encrypted_value}:#{salt}:#{signature}"
    end

    def decrypt_value(blob) # rubocop:disable Metrics/CyclomaticComplexity, Metrics/MethodLength
      unless blob.is_a?(String)
        raise Errors::DecryptionError,
          "Expecting an encrypted blob but got '#{blob}'"
      end

      iv_b64, enc_sym_key_b64, encrypted_value_b64, salt, signature = blob.split(':')

      if signature.nil? || salt.nil? || encrypted_value_b64.nil? ||
          enc_sym_key_b64.nil? || iv_b64.nil?
        raise Errors::DecryptionError,
          "Invalid blob format '#{blob}'. " \
          'Did you encrypt this with an older version of Arcanus?'
      end

      iv = Base64.decode64(iv_b64)
      sym_key = @key.decrypt(Base64.decode64(enc_sym_key_b64))
      ENCRYPTION_CIPHER.reset.decrypt
      ENCRYPTION_CIPHER.iv = iv
      ENCRYPTION_CIPHER.key = sym_key
      value = ENCRYPTION_CIPHER.update(Base64.decode64(encrypted_value_b64)) +
        ENCRYPTION_CIPHER.final

      actual_signature = Digest::SHA2.new(SIGNATURE_SIZE_BITS).tap do |digest|
        digest << salt
        digest << value
      end.to_s

      if signature != actual_signature
        raise Errors::DecryptionError,
          'Signature of decrypted value does not match: ' \
          "expected #{signature} but got #{actual_signature}"
      end

      value
    end
  end
end
