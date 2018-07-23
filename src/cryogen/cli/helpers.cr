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
        if ENV["CRYOGEN_KEY"]?
          Key.from_base64(ENV["CRYOGEN_KEY"]) 
        elsif File.exists?(Cryogen::KEY_FILE)
          Key.load(Cryogen::KEY_FILE)
        elsif STDIN.tty?
          key = prompt("Enter the key and hit [Return]:", echo: false)
          Key.from_base64(key)
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

      def prompt(prompt_str : String, echo : Bool = true) : String
        require_tty!
        print "#{prompt_str} "
        raw_input = echo ? gets : STDIN.noecho(&.gets)
        puts unless echo # this is silly
        raw_input.to_s.chomp
      end
    end
  end
end
