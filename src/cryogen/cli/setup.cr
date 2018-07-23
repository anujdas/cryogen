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

        Dir.mkdir_p(Cryogen::BASE_DIR) unless Dir.exists?(Cryogen::BASE_DIR)

        key = Key.generate
        UnlockedVault.new.lock!(key).save!(Cryogen::VAULT_FILE)

        success "Vault created! Commit #{Cryogen::VAULT_FILE} to version control. Use `cryogen edit` to add values."
        puts "Your key is:"
        puts key.to_base64.colorize.mode(:underline)
        warn "Save this key securely! Without it, you will NOT be able to access or edit your vault.", important: true

        if prompt("Save key to file now? [Y/n]") == "Y"
          key.save!(Cryogen::KEY_FILE)
          warn "Vault unlocked! MAKE SURE that you add #{Cryogen::KEY_FILE} to your .gitignore (or equivalent) to avoid mishaps."
        else
          puts "Use the `cryogen unlock` command to unlock your chest for editing, or pass $CRYOGEN_KEY to avoid persisting to disk."
        end
      end

      private def handle_existing_vault!
        return unless File.exists?(Cryogen::KEY_FILE) || File.exists?(Cryogen::VAULT_FILE)

        raise Error::VaultInitialised.new unless flags.force

        yes_no = prompt("Are you sure you want to delete the existing key and vault? This action cannot be undone! [Y/n]:", important: true)
        raise Error::OperationCancelled.new unless "Y" == yes_no

        File.delete(Cryogen::KEY_FILE) if File.exists?(Cryogen::KEY_FILE)
        File.delete(Cryogen::VAULT_FILE) if File.exists?(Cryogen::VAULT_FILE)
      end
    end
  end
end
