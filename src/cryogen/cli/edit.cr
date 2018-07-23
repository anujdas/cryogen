require "admiral"
require "tempfile"

require "./helpers"

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
          edit_file(tempfile.path)
          UnlockedVault.load(tempfile.path).lock!(key).save!(Cryogen::VAULT_FILE)
          success "Vault updated! Make sure to commit any changes to #{Cryogen::VAULT_FILE}"
        ensure
          tempfile.delete
        end
      end

      private def edit_file(filename : String)
        unless system(ENV["EDITOR"], [filename])
          raise Error::EditorFailed.new 
        end
      end
    end
  end
end
