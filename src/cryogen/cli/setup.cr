require "admiral"

require "./helpers"

module Cryogen
  module CLI
    class Setup < Admiral::Command
      include Helpers

      define_help description: "Initializes an empty vault in the current directory"
      define_flag force : Bool, description: "Deletes the existing key and vault, if present, before proceeding."

      def run
        require_tty!
        handle_existing_vault!

        password = prompt("Enter a password (the encryption key will be derived from it, so make it secure and save it!):")
        key = Key.from_password(password)

        Dir.mkdir_p(Cryogen::BASE_DIR) unless Dir.exists?(Cryogen::BASE_DIR)
        UnlockedVault.new.lock!(key).save!(Cryogen::VAULT_FILE)
        key.save!(Cryogen::KEY_FILE)

        puts "Vault created! Commit #{Cryogen::VAULT_FILE} to version control. Use `cryogen edit` to add values.".colorize(:green)
        puts "Key persisted! Add #{Cryogen::KEY_FILE} to your .gitignore (or equivalent) to avoid mishaps.".colorize(:yellow)
      end

      private def handle_existing_vault!
        return unless File.exists?(Cryogen::KEY_FILE) || File.exists?(Cryogen::VAULT_FILE)

        raise Error::VaultInitialised.new unless flags.force

        print "Are you sure you want to delete the existing key and vault? This action cannot be undone! [Y/n]: "
        raise Error::OperationCancelled.new unless "Y" == gets("\n").to_s.strip

        File.delete(Cryogen::KEY_FILE) if File.exists?(Cryogen::KEY_FILE)
        File.delete(Cryogen::VAULT_FILE) if File.exists?(Cryogen::VAULT_FILE)
      end
    end
  end
end
