require "admiral"

require "../key"

module Cryogen
  module Command
    class Unlock < Admiral::Command
      define_help description: "Saves the chest key for passwordless use"

      def run
        if !File.exists?(Cryogen::CHEST_FILE)
          raise "Chest file not found -- have you called `cryogen setup` yet?"
        elsif File.exists?(Cryogen::KEY_FILE)
          raise "Chest already unlocked -- nothing to do!"
        end

        print "Enter the password and hit [Enter]: "
        key = Key.from_password(gets.to_s)
        key.save!(Cryogen::KEY_FILE)
        puts "Key persisted! Add .cryogen/key to your .gitignore (or equivalent) to avoid mishaps."
      end
    end
  end
end
