require "./cryogen/*"

module Cryogen
  BASE_DIR = ".cryogen"
  VAULT_FILE = "#{BASE_DIR}/vault.yml"
  KEY_FILE = "#{BASE_DIR}/secret_key"
end

Cryogen::CLI::Main.run
