require "file"

require "./error"
require "./key"
require "./vault_entry"

module Cryogen
  abstract struct Vault
    def self.load(vault_file : String) : self
      File.open(vault_file, "r") { |f| new(VaultEntry.from_yaml(f)) }
    rescue e : YAML::ParseException
      raise Error::VaultInvalid.new(e)
    end

    delegate to_yaml, to: @contents

    def initialize(@contents : VaultEntry = VaultEntry.empty)
    end

    def save!(vault_file : String)
      File.open(vault_file, "w") { |f| to_yaml(f) }
    end

    protected def contents : VaultEntry
      @contents
    end
  end

  struct LockedVault < Vault
    def merge(modified_vault : self, key : Key) : self
      self.class.new(@contents.merge_encrypted(modified_vault.contents, key))
    end

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
