require "admiral"
require "tempfile"

require "./helpers"
require "../error"

module Cryogen
  module CLI
    class Edit < Admiral::Command
      include Helpers

      define_help description: "Opens $EDITOR to edit the current vault"

      def run
        require_vault!
        require_editor!

        # dump unencrypted contents for manual editing
        key = obtain_key!
        tempfile = Tempfile.open("vault", ".yml") do |f|
          LockedVault.load(Cryogen::VAULT_FILE).unlock!(key).to_yaml(f)
          f.flush # force buffer write to disk
        end

        begin
          vault = edit_until_valid(tempfile.path)
          vault.lock!(key).save!(Cryogen::VAULT_FILE)
          success "Vault updated! Make sure to commit any changes to #{Cryogen::VAULT_FILE}"
        ensure
          tempfile.delete
        end
      end

      private def edit_until_valid(filename : String) : UnlockedVault
        loop do
          raise Error::EditorFailed.new unless system(ENV["EDITOR"], [filename])
          break UnlockedVault.load(filename)
        rescue e : Error::VaultInvalid
          error e.message
          raise e unless "Y" == prompt("Continue editing? Otherwise, changes will be discarded. [Y/n]:")
        end
      end
    end
  end
end
