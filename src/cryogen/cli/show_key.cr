require "admiral"
require "file"

require "./helpers"

module Cryogen
  module CLI
    class ShowKey < Admiral::Command
      include Helpers

      define_help description: "Displays the key for the current unlocked vault"

      def run
        require_unlocked_vault!
        puts "Your key is:"
        puts Key.load(Cryogen::KEY_FILE).to_base64.colorize.mode(:underline)
        warn "Save this key securely! Without it, you will NOT be able to access or edit your vault.", important: true
      end
    end
  end
end
