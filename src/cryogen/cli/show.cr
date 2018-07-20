require "admiral"
require "file"

require "./helpers"

module Cryogen
  module CLI
    class Show < Admiral::Command
      include Helpers

      define_help description: "Displays the decrypted contents of this directory's vault"

      def run
        require_vault!
        key = obtain_key!
        vault = LockedVault.load(Cryogen::VAULT_FILE).unlock!(key)
        puts vault.to_yaml
      end
    end
  end
end
