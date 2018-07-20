require "admiral"
require "file"

require "../vault"
require "../key"

module Cryogen
  module Command
    class Export < Admiral::Command
      define_help description: "Exports the unlocked vault in a shell-friendly (ENV variable) format"
      define_flag no_subprocess : Bool, description: "Skips prepending of `export` to ENV vars, making them invisible to subprocesses"

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
        vault.to_env.each do |prefix, value|
          puts "#{"export " if flags.no_subprocess}#{prefix}=#{value}"
        end
      end
    end
  end
end
