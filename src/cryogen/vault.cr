require "file"

require "./key"
require "./vault_entry"

module Cryogen
  abstract struct Vault
    def self.load(vault_file : String) : self
      File.open(vault_file, "r") { |f| new(VaultEntry.from_yaml(f)) }
    end

    delegate to_yaml, to: @contents

    def initialize(@contents : VaultEntry = VaultEntry.empty)
    end

    def save!(vault_file : String)
      File.open(vault_file, "w") { |f| to_yaml(f) }
    end
  end

  struct LockedVault < Vault
    def unlock!(key : Key) : UnlockedVault
      UnlockedVault.new(@contents.decrypt(key))
    end
  end

  struct UnlockedVault < Vault
    delegate to_env, to: @contents

    def lock!(key : Key) : LockedVault
      LockedVault.new(@contents.encrypt(key))
    end
  end
end
