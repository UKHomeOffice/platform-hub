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
          @docs_source.update! kind: :hosted_gitlab_repo
        }.to raise_error(
          ActiveRecord::ReadOnlyRecord,
          "kind can't be modified"
        )

        expect(@docs_source.reload.github_repo?).to be true
      end
    end
  end

end
