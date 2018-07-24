require "./spec_helper"

describe Cryogen do
  it "stores vault and key in the same hidden directory" do
    Cryogen::BASE_DIR.should start_with(".")
    Cryogen::VAULT_FILE.should start_with(Cryogen::BASE_DIR)
    Cryogen::KEY_FILE.should start_with(Cryogen::BASE_DIR)
  end
end
