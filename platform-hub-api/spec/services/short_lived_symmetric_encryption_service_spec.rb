require 'rails_helper'

describe ShortLivedSymmetricEncryptionService, type: :service do

  let(:string) { 'foobar' }

  before do
    @service = ShortLivedSymmetricEncryptionService.new 'my secret key'
  end

  it 'should encrypt and decrypt a string as expected' do
    result = @service.decrypt(@service.encrypt(string))
    expect(result).to eq string
  end

  it 'should be tied to that specific secret key' do
    other_service = ShortLivedSymmetricEncryptionService.new 'a totally different secret key'
    result_0 = other_service.decrypt(other_service.encrypt(string))
    result_1 = @service.decrypt(other_service.encrypt(string))
    result_2 = other_service.decrypt(@service.encrypt(string))

    expect(result_0).to eq string
    expect(result_1).to be nil
    expect(result_2).to be nil
  end

end
