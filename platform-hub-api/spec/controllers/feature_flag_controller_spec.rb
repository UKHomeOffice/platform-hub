require 'rails_helper'

RSpec.describe FeatureFlagsController, type: :controller do

  include_context 'time helpers'

  before do
    @flag1 = 'some-feature'
    @state1 = false
    @flag2 = 'other-feature'
    @state2 = true

    create(:feature_flags_hash_record,
      data: {
        @flag1 => @state1,
        @flag2 => @state2
      }
    )
  end

  describe 'GET #index' do

    it_behaves_like 'unauthenticated not allowed' do
      before do
        get :index
      end
    end

    it_behaves_like 'authenticated' do

      it 'presents all feature flags' do
        get :index

        expect(response).to be_success
        expect(json_response.count).to be 2
        expect(json_response[@flag1]).to eq @state1
        expect(json_response[@flag2]).to eq @state2
      end

    end
  end  

end
