require 'rails_helper'
require 'rails_helper'

RSpec.describe SupportRequestTemplate, type: :model do

  describe 'a valid SupportRequestTemplate instance' do

    before do
      @srt = create :support_request_template, fields_count: 2
    end

    it 'persists as expected, handling embedded JSON fields' do

      expect(SupportRequestTemplate.count).to eq 1

      srt = SupportRequestTemplate.first

      expect(srt.shortname).to eq @srt.shortname
      expect(srt.git_hub_repo).to eq @srt.git_hub_repo
      expect(srt.title).to eq @srt.title
      expect(srt.description).to eq @srt.description

      expect(srt.form_spec).not_to be_empty
      expected_form_spec = Hashie::Mash.new @srt.form_spec
      loaded_form_spec = Hashie::Mash.new srt.form_spec
      expect(loaded_form_spec).to eq expected_form_spec

      expect(srt.git_hub_issue_spec).not_to be_empty
      expected_git_hub_issue_spec = Hashie::Mash.new @srt.git_hub_issue_spec
      loaded_git_hub_issue_spec = Hashie::Mash.new srt.git_hub_issue_spec
      expect(loaded_git_hub_issue_spec).to eq expected_git_hub_issue_spec

    end
  end

end
