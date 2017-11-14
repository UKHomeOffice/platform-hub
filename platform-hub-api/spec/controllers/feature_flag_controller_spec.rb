require 'rails_helper'

RSpec.describe FeatureFlagsController, type: :controller do

  include_context 'time helpers'

  describe 'GET #index' do

    it_behaves_like 'unauthenticated not allowed' do
      before do
        get :index
      end
    end

    it_behaves_like 'authenticated' do

      before do
        @flag1 = 'some-feature'
        @state1 = false
        @flag2 = 'other-feature'
        @state2 = true

        create(:feature_flags_hash_record,
          flags: {
            @flag1 => @state1,
            @flag2 => @state2
          }
        )
      end

      it 'presents all feature flags' do
        get :index

        expect(response).to be_success
        expect(json_response.count).to be 2
        expect(json_response[@flag1]).to eq @state1
        expect(json_response[@flag2]).to eq @state2
      end

    end
  end

  describe 'PUT #update_flag' do

    let(:flag1) { 'feature-1' }
    let(:flag2) { 'feature-2' }

    before do
      create(:feature_flags_hash_record,
        flags: {
          flag1 => false,
        }
      )
    end

    it_behaves_like 'unauthenticated not allowed' do
      before do
        put :update_flag, params: { flag: flag1 }
      end
    end

    it_behaves_like 'authenticated' do

      it_behaves_like 'not a hub admin so forbidden'  do
        before do
          put :update_flag, params: { flag: flag1 }
        end
      end

      it_behaves_like 'a hub admin' do

        it 'sets an existing flag to true' do
          put :update_flag, params: { flag: flag1, feature_flag: { state: true } }
          expect(response).to be_success
          expect(json_response).to eq({
            flag1 => true
          })
        end

        it 'sets an existing flag to false' do
          FeatureFlagService.create_or_update flag1, true
          expect(FeatureFlagService.is_enabled?(flag1)).to be true
          put :update_flag, params: { flag: flag1, feature_flag: { state: false } }
          expect(response).to be_success
          expect(json_response).to eq({
            flag1 => false
          })
        end

        it 'creates a flag that doesn\'t exist yet and sets it to true' do
          put :update_flag, params: { flag: flag2, feature_flag: { state: true } }
          expect(response).to be_success
          expect(json_response).to eq({
            flag1 => false,
            flag2 => true
          })
        end

        it 'creates a flag that doesn\'t exist yet and sets it to false' do
          put :update_flag, params: { flag: flag2, feature_flag: { state: false } }
          expect(response).to be_success
          expect(json_response).to eq({
            flag1 => false,
            flag2 => false
          })
        end

        it 'creates a flag that doesn\'t exist yet and uses the string \'false\'' do
          put :update_flag, params: { flag: flag2, feature_flag: { state: 'false' } }
          expect(response).to be_success
          expect(json_response).to eq({
            flag1 => false,
            flag2 => false
          })
        end

      end

    end

  end

end
