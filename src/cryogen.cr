require "./cryogen/cli"

module Cryogen
  BASE_DIR = ".cryogen"
  CHEST_FILE = "#{BASE_DIR}/chest.yml"
  KEY_FILE = "#{BASE_DIR}/key"
end

Cryogen::CLI.run
