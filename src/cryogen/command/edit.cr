require "admiral"
require "tempfile"

require "../vault"
require "../key"

module Cryogen
  module Command
    class Edit < Admiral::Command
      define_help description: "Opens $EDITOR to edit the current vault"

      def run
        unless ENV["EDITOR"]?
          raise "$EDITOR not set -- try, e.g., `export EDITOR=nano` before proceeding."
        end

        unless File.exists?(Cryogen::VAULT_FILE)
          raise "Vault file not found -- have you called `cryogen setup` yet?"
        end

        key = if File.exists?(Cryogen::KEY_FILE)
                Key.load(Cryogen::KEY_FILE)
              elsif ENV["CRYOGEN_PASSWORD"]?
                Key.from_password(ENV["CRYOGEN_PASSWORD"]) 
              else
                raise "Key not found -- did you unlock the vault or pass CRYOGEN_PASSWORD?"
              end

        # dump unencrypted contents for manual editing
        tempfile = Tempfile.open("vault", ".yml") do |f|
          LockedVault.load(Cryogen::VAULT_FILE).unlock!(key).to_yaml(f)
          f.flush # force buffer write to disk
        end

        begin
          unless system(ENV["EDITOR"], [tempfile.path])
            raise "Editor exited unsuccessfully; reverting changes."
          end
          UnlockedVault.load(tempfile.path).lock!(key).save!(Cryogen::VAULT_FILE)
          puts "Vault updated! Make sure to commit any changes to #{Cryogen::VAULT_FILE}"
        ensure
          tempfile.delete
        end
      end
    end
  end
end
