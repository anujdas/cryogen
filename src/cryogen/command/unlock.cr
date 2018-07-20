require "admiral"

require "../vault"
require "../key"

module Cryogen
  module Command
    class Unlock < Admiral::Command
      define_help description: "Saves the vault key for passwordless use"

      def run
        if !File.exists?(Cryogen::VAULT_FILE)
          raise "Vault file not found -- have you called `cryogen setup` yet?"
        elsif File.exists?(Cryogen::KEY_FILE)
          raise "Vault already unlocked -- nothing to do!"
        end

        key = if ENV["CRYOGEN_PASSWORD"]?
                Key.from_password(ENV["CRYOGEN_PASSWORD"]) 
              elsif STDIN.tty?
                print "Enter the password and hit [Enter]: "
                Key.from_password(gets.to_s)
              else
                raise "Key not found -- use a TTY or pass CRYOGEN_PASSWORD"
              end

        LockedVault.load(Cryogen::VAULT_FILE).unlock!(key) # test decryption
        key.save!(Cryogen::KEY_FILE)

        puts "Key persisted! Add #{Cryogen::KEY_FILE} to your .gitignore (or equivalent) to avoid mishaps."
      end
    end
  end
end
