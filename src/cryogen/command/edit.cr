require "admiral"

require "../chest"
require "../key"

module Cryogen
  module Command
    class Edit < Admiral::Command
      define_help description: "Opens $EDITOR to edit the current chest"

      def run
        unless ENV["EDITOR"]
          raise "$EDITOR not set -- try, e.g., `export EDITOR=nano` before proceeding."
        end

        unless File.exists?(Cryogen::CHEST_FILE)
          raise "Chest file not found -- have you called `cryogen setup` yet?"
        end

        key = if File.exists?(Cryogen::KEY_FILE)
                Key.load(Cryogen::KEY_FILE)
              elsif ENV["CRYOGEN_PASSWORD"]?
                Key.from_password(ENV["CRYOGEN_PASSWORD"]) 
              else
                raise "Key not found -- did you unlock the chest or pass CRYOGEN_PASSWORD?"
              end

        chest = Chest.new(Cryogen::CHEST_FILE, key)
      end
    end
  end
end
