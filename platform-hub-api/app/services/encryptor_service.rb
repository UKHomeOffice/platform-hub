class EncryptorService
  def initialize(secret_key_base)
    # (shaun-scaling) MessageEncryptor always truncates to keylen. In newer versions of ruby
    # This now throws an error if the key is != key_len. Previously it was
    # just swallowed silently. Default is 'aes-256-gcm' which has a 256bit/32byte key len.
    # https://api.rubyonrails.org/classes/ActiveSupport/MessageEncryptor.html#method-c-new
    # https://github.com/ruby/ruby/commit/ce63526
    # https://github.com/rails/rails/issues/25185
    @encryptor = ActiveSupport::MessageEncryptor.new(secret_key_base[0, ActiveSupport::MessageEncryptor.key_len])
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
