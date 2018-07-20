require "admiral"

require "./helpers"

module Cryogen
  module CLI
    class Lock < Admiral::Command
      include Helpers

      define_help description: "Deletes the persisted vault key"

      def run
        require_unlocked_vault!
        File.delete(Cryogen::KEY_FILE)
        puts "Key deleted! Use `cryogen unlock` to unlock again, or set $CRYOGEN_PASSWORD to avoid persisting sensitive data.".colorize(:green)
      end
    end
  end
end
