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
        success "Key deleted! Use `cryogen unlock` to unlock again, or set $CRYOGEN_KEY to avoid persisting sensitive data."
      end
    end
  end
end
