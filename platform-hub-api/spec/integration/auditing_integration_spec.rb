require 'rails_helper'

RSpec.describe 'Auditing integration' do

  # This uses the real models, but in a contrived way, to test that the auditing
  # works as intended.

  let :action do
    'hammertime'
  end

  before do
    @auditor = create :user
    @identity = create :identity
    @identity_owner = @identity.user
  end

  it 'should create an Audit record as expected and not allow it to be updated or deleted' do
    expect(Audit.count).to eq 0

    Audit.create(
      action: action,
      auditable: @identity,
      user: @auditor
    )

    expect(Audit.count).to eq 1

    audit = Audit.first

    expect(audit.action).to eq action
    expect(audit.auditable).to eq @identity
    expect(audit.auditable_descriptor).to eq @identity.provider
    expect(audit.associated).to eq @identity_owner
    expect(audit.associated_descriptor).to eq @identity_owner.email
    expect(audit.user).to eq @auditor
    expect(audit.user_name).to eq @auditor.name
    expect(audit.user_email).to eq @auditor.email

    expect {
      audit.comment = 'fooooo'
      audit.save!
    }.to raise_error(ActiveRecord::ReadOnlyRecord)

    expect {
      audit.destroy
    }.to raise_error(ActiveRecord::ReadOnlyRecord)
  end

end
