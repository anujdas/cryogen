require "admiral"
require "file"

require "../chest"
require "../key"

module Cryogen
  module Command
    class Show < Admiral::Command
      define_flag chest_file, default: "./.cryogen/chest.yml"
      define_flag key_file, default: "./.cryogen/key"

      def run
        key = 
          if File.exists?(flags.key_file)
            Key.from_file(flags.key_file)
          elsif ENV["CRYOGEN_PASSWORD"]
            Key.from_password(ENV["CRYOGEN_PASSWORD"]) 
          end

        unless key
          raise "Key not found -- did you unlock the chest or pass CRYOGEN_PASSWORD?"
        end

        unless File.exists?(flags.chest_file)
          raise "Chest file not found -- have you called `cryogen setup` yet?"
        end

        chest = Chest.new(flags.chest_file, key)
        puts chest.decrypted_contents.to_yaml
      end
    end
  end
end
