require "admiral"

require "./command/*"

module Cryogen
  class CLI < Admiral::Command
    register_sub_command setup : Command::Setup, description: "Initialize a vault in this directory"
    register_sub_command show : Command::Show, description: "Show decrypted contents of vault"
    register_sub_command export : Command::Export,
      description: "Print decrypted vault contents in shell `eval`-able ENV format"
    register_sub_command edit : Command::Edit, description: "Opens the vault in $EDITOR"
    register_sub_command unlock : Command::Unlock, description: "Unlock the vault"
    register_sub_command lock : Command::Lock, description: "Lock the vault"

    define_help description: "A tool for managing secrets"
    define_version VERSION

    def run
      puts help
    end
  end
end
