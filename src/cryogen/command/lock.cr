require "admiral"

module Cryogen
  module Command
    class Lock < Admiral::Command
      define_help description: "Deletes the persisted vault key"

      def run
        if !File.exists?(Cryogen::VAULT_FILE)
          raise "Vault file not found -- have you called `cryogen setup` yet?"
        elsif !File.exists?(Cryogen::KEY_FILE)
          raise "Vault already locked -- nothing to do!"
        end

        File.delete(Cryogen::KEY_FILE)
        puts "Key deleted! Use `cryogen unlock` to unlock again, or set $CRYOGEN_PASSWORD to avoid persisting sensitive data."
      end
    end
  end
end
