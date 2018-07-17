require "admiral"

require "./command/*"

module Cryogen
  class CLI < Admiral::Command
    register_sub_command setup : Command::Setup, description: "Initialize a chest in this directory"
    register_sub_command show : Command::Show, description: "Show decrypted contents of chest"

    define_help description: "A tool for managing secrets"

    def run
      puts help
    end
  end
end
