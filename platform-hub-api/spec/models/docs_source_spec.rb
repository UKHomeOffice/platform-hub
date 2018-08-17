require 'rails_helper'

RSpec.describe DocsSource, type: :model do

  describe 'read only attributes' do
    before do
      @docs_source = create(
        :docs_source,
        kind: :github_repo
      )
    end

    describe '#kind' do
      it 'does not allow you to update the kind' do
        expect {
          @docs_source.update! kind: :gitlab_repo
        }.to raise_error(
          ActiveRecord::ReadOnlyRecord,
          "kind can't be modified"
        )
      end
    end
  end

end
