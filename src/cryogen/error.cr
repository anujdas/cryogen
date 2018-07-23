require "openssl/cipher"
require "yaml"

module Cryogen
  class Error < Exception
    class KeyInvalid < Error
      def initialize
        super "The provided key was invalid; check it and try again"
      end
    end

    class SignatureInvalid < Error
      def initialize
        super "Signature integrity check failed during decryption"
      end
    end

    class VaultNotFound < Error
      def initialize
        super "Vault file not found -- have you called `cryogen setup` yet?"
      end
    end

    class VaultInitialised < Error
      def initialize
        super "Vault and/or key found -- are you sure cryogen has not already been set up?"
      end
    end

    class VaultLocked < Error
      def initialize
        super "Vault locked -- unlock with `cryogen unlock` before attempting this operation"
      end
    end

    class VaultUnlocked < Error
      def initialize
        super "Vault unlocked -- lock with `cryogen lock` before attempting this operation"
      end
    end

    class KeyNotFound < Error
      def initialize
        super "Key not found -- did you unlock the vault or pass CRYOGEN_KEY?"
      end
    end

    class VaultInvalid < Error
      def initialize(yaml_exc : YAML::ParseException)
        super "Invalid vault! Keys and values must be strings. #{yaml_exc.message}"
      end
    end

    class DecryptionError < Error
      def initialize(openssl_error : OpenSSL::Cipher::Error)
        super "Decryption failed! Make sure you have the right key. (#{openssl_error.message})"
      end
    end

    class TTYRequired < Error
      def initialize
        super "TTY required for this operation; try again from an interactive console"
      end
    end

    class OperationCancelled < Error
      def initialize
        super "Cancelling operation"
      end
    end

    class EditorNotSet < Error
      def initialize
        super "$EDITOR not set -- try, e.g., `export EDITOR=nano` before proceeding."
      end
    end

    class EditorFailed < Error
      def initialize
        super "Editor exited unsuccessfully; changes not applied."
      end
    end

    def initialize(message : String?)
      message ||= "An unknown error occurred during operation"
      super message
    end
  end
end
