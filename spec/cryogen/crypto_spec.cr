require "../spec_helper"
require "base64"

describe Cryogen::Crypto do
  plaintext = "\0" * 16
  key = Cryogen::Key.from_base64(Base64.strict_encode("\0" * 64))
  ciphertext = Cryogen::Crypto.encrypt_and_sign(plaintext, key)

  describe ".encrypt_and_sign" do
    it "returns a single delimited string" do
      ciphertext.should match /^.+\$.+\$.+$/
    end
  end

  describe ".verify_and_decrypt" do
    it "fails if the cipher key is incorrect" do
      wrong_key = Cryogen::Key.from_base64(Base64.strict_encode("\1" * 32 + "\0" * 32))
      expect_raises Cryogen::Error::DecryptionError do
        Cryogen::Crypto.verify_and_decrypt(ciphertext, wrong_key)
      end
    end

    it "fails if the ciphertext is modified" do
      expect_raises Cryogen::Error::SignatureInvalid do
        Cryogen::Crypto.verify_and_decrypt("A#{ciphertext}", key)
      end
    end

    it "returns the plaintext given the right key" do
      Cryogen::Crypto.verify_and_decrypt(ciphertext, key).should eq plaintext
    end
  end
end
