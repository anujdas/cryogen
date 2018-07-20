require "admiral"
require "file"

require "../vault"
require "../key"

module Cryogen
  module Command
    class Show < Admiral::Command
      define_help description: "Displays the decrypted contents of this directory's vault"

      def run
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

        vault = LockedVault.load(Cryogen::VAULT_FILE).unlock!(key)
        puts vault.to_yaml
      end
    end
  end
end
