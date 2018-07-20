require "../error"
require "../key"
require "../vault"

module Cryogen
  module CLI
    module Helpers
      extend self

      def require_vault!
        raise Error::VaultNotFound.new unless File.exists?(Cryogen::VAULT_FILE)
      end

      def require_unlocked_vault!
        require_vault!
        raise Error::VaultLocked.new unless File.exists?(Cryogen::KEY_FILE)
      end

      def require_locked_vault!
        require_vault!
        raise Error::VaultUnlocked.new if File.exists?(Cryogen::KEY_FILE)
      end

      def obtain_key! : Key
        if File.exists?(Cryogen::KEY_FILE)
          Key.load(Cryogen::KEY_FILE)
        elsif ENV["CRYOGEN_PASSWORD"]?
          Key.from_password(ENV["CRYOGEN_PASSWORD"]) 
        elsif STDIN.tty?
          password = prompt("Enter the password and hit [Enter]:")
          Key.from_password(password)
        else
          raise Error::KeyNotFound.new
        end
      end

      def require_tty!
        raise Error::TTYRequired.new unless STDIN.tty?
      end

      def require_editor!
        require_tty!
        raise Error::EditorNotSet.new unless ENV["EDITOR"]?
      end

      def prompt(prompt_str : String) : String
        require_tty!
        print "#{prompt_str} "
        gets("\n").to_s.strip
      end
    end
  end
end
