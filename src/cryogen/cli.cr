require "admiral"
require "colorize"

Colorize.on_tty_only! # turn on STDOUT/STDERR colours if available

require "./cli/*"
require "./error"

module Cryogen
  module CLI
    class Main < Admiral::Command
      register_sub_command setup : CLI::Setup, description: "Initialize a vault in this directory"
      register_sub_command show : CLI::Show, description: "Show decrypted contents of vault"
      register_sub_command show_key : CLI::ShowKey, description: "Display vault decryption key"
      register_sub_command export : CLI::Export,
        description: "Print decrypted vault contents in shell `eval`-able ENV format"
      register_sub_command edit : CLI::Edit, description: "Open the vault in $EDITOR"
      register_sub_command unlock : CLI::Unlock, description: "Unlock the vault"
      register_sub_command lock : CLI::Lock, description: "Lock the vault"
      register_sub_command rekey : CLI::Rekey, description: "Rotate the vault key"

      define_help description: "A tool for managing secrets"
      define_version VERSION

      rescue_from Error do |e|
        panic e.message.colorize(:red)
      end

      def run
        puts help
      end
    end
  end
end
