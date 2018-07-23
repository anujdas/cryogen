require "admiral"

require "./helpers"

module Cryogen
  module CLI
    class Rekey < Admiral::Command
      include Helpers

      define_help description: "Changes the key for the existing vault, disabling the previous key"

      def run
        current_key = obtain_key!
        vault = LockedVault.load(Cryogen::VAULT_FILE).unlock!(current_key)

        warn "Are you sure you want to change the vault key? This will invalidate the previous key!"
        raise Error::OperationCancelled.new unless "Y" == prompt("Proceed? [Y/n]:")

        key = Key.generate
        vault.lock!(key).save!(Cryogen::VAULT_FILE)
        File.delete(Cryogen::KEY_FILE)

        puts "Your new key is:"
        puts key.to_base64.colorize.mode(:underline)
        warn "Save this key securely! Without it, you will NOT be able to access or edit your vault.", important: true

        if prompt("Save new key to file now? [Y/n]") == "Y"
          key.save!(Cryogen::KEY_FILE)
          warn "Vault unlocked! MAKE SURE that you add #{Cryogen::KEY_FILE} to your .gitignore (or equivalent) to avoid mishaps."
        else
          puts "Use the `cryogen unlock` command to unlock your chest for editing, or pass $CRYOGEN_KEY to avoid persisting to disk."
        end
      end
    end
  end
end
