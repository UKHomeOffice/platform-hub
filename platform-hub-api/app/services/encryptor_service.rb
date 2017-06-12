class EncryptorService
  def initialize(secret_key_base)
    @encryptor = ActiveSupport::MessageEncryptor.new(secret_key_base)
  end

  def encrypt(plaintext)
    @encryptor.encrypt_and_sign(plaintext)
  end

  def decrypt(encrypted_data)
    @encryptor.decrypt_and_verify(encrypted_data)
  rescue ActiveSupport::MessageVerifier::InvalidSignature
    nil
  end
end
