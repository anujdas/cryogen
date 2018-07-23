require "admiral"

require "./helpers"

module Cryogen
  module CLI
    class Unlock < Admiral::Command
      include Helpers

      define_help description: "Saves the vault key for non-interactive use"

      def run
        require_tty!
        require_locked_vault!

        key = obtain_key!
        LockedVault.load(Cryogen::VAULT_FILE).unlock!(key) # test decryption
        key.save!(Cryogen::KEY_FILE)

        success "Key persisted! Add #{Cryogen::KEY_FILE} to your .gitignore (or equivalent) to avoid mishaps."
      end
    end
  end
end
