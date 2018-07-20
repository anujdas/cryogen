require "admiral"
require "file"

require "./helpers"

module Cryogen
  module CLI
    class Export < Admiral::Command
      include Helpers

      define_help description: "Exports the unlocked vault in a shell-friendly (ENV variable) format"
      define_flag no_subprocess : Bool, description: "Skips prepending of `export` to ENV vars, making them invisible to subprocesses"

      def run
        require_vault!
        key = obtain_key!
        vault = LockedVault.load(Cryogen::VAULT_FILE).unlock!(key)
        vault.to_env.each do |prefix, value|
          puts "#{"export " unless flags.no_subprocess}#{prefix}=#{value}"
        end
      end
    end
  end
end
