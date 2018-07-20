require "admiral"

require "../chest"
require "../key"

module Cryogen
  module Command
    class Setup < Admiral::Command
      define_help description: "Initializes an empty chest in the current directory"
      define_flag force : Bool, description: "Deletes the existing key and chest, if present, before proceeding."

      def run
        if File.exists?(Cryogen::KEY_FILE) || File.exists?(Cryogen::CHEST_FILE)
          if flags.force
            print "Are you sure you want to delete the existing key and chest? This action cannot be undone! [Y/n]: "
            if "Y" == gets
              File.delete(Cryogen::KEY_FILE) if File.exists?(Cryogen::KEY_FILE)
              File.delete(Cryogen::CHEST_FILE) if File.exists?(Cryogen::CHEST_FILE)
            else
              raise "Cancelling"
            end
          else
            raise "Chest and/or key found -- are you sure cryogen has not already been set up?"
          end
        end

        print "Enter a password (the encryption key will be derived from it, so make it secure and save it!): "
        password = gets
        raise "Password must be non-empty (and preferably, 10+ characters)!" unless password.is_a?(String)
        key = Key.from_password(password)

        puts "Creating chest..."
        Dir.mkdir(Cryogen::BASE_DIR) unless Dir.exists?(Cryogen::BASE_DIR)
        Chest.new(Cryogen::CHEST_FILE, key).update_contents!(Cryogen::Chest.blank_contents)
        key.save!(Cryogen::KEY_FILE)
        puts "Key persisted! Add .cryogen/key to your .gitignore (or equivalent) to avoid mishaps."
        puts "Commit .cryogen/chest.yml to version control. Use `cryogen edit` to add values."
      end
    end
  end
end
