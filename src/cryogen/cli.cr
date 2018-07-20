require "admiral"

require "./command/*"

module Cryogen
  class CLI < Admiral::Command
    register_sub_command setup : Command::Setup, description: "Initialize a chest in this directory"
    register_sub_command show : Command::Show, description: "Show decrypted contents of chest"
    register_sub_command edit : Command::Edit, description: "Opens the chest in $EDITOR"
    register_sub_command unlock : Command::Unlock, description: "Unlock the chest"
    register_sub_command lock : Command::Lock, description: "Lock the chest"

    define_help description: "A tool for managing secrets"

    def run
      puts help
    end
  end
end
