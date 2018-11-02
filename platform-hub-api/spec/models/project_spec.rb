require 'rails_helper'

RSpec.describe Project, type: :model do

  describe '#shortname' do
    before do
      @project = create :project, shortname: 'Foo'
    end

    it 'is readonly' do
      expect {
        @project.update! shortname: 'Bar'
      }.to raise_error(
        ActiveRecord::ReadOnlyRecord,
        "shortname can't be modified"
      )

      expect(@project.reload.shortname).to eq 'Foo'
    end
  end

end
