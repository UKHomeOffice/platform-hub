RSpec.shared_examples 'validates hashes' do
  it 'calls the .validate_hashes_validation method' do
    expect(subject).to receive(:validate_hashes_validation).once
    subject.valid?
  end
end
