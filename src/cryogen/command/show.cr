require "admiral"
require "file"

require "../chest"
require "../key"

module Cryogen
  module Command
    class Show < Admiral::Command
      define_help description: "Displays the decrypted contents of this directory's chest"

      def run
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
        puts chest.decrypted_contents.to_yaml
      end
    end
  end
end
