require "admiral"

require "./command/*"

module Cryogen
  class CLI < Admiral::Command
    register_sub_command show : Command::Show, description: "Show decrypted contents of chest"

    def run
    end
  end
end
