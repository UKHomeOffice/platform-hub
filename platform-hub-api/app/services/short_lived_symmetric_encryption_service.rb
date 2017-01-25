class ShortLivedSymmetricEncryptionService

  def initialize secret_key
    @secret_key = secret_key
  end

  def encrypt string
    Base64.encode64(gibberish.encrypt(string))
  end

  def decrypt cipher
    begin
      gibberish.decrypt(Base64.decode64(cipher))
    rescue Gibberish::AES::SJCL::DecryptionError
      nil
    end
  end

  protected

  def gibberish
    @gibberish ||= Gibberish::AES.new(@secret_key)
  end

end
