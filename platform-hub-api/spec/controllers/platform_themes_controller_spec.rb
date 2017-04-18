require 'rails_helper'

RSpec.describe PlatformThemesController, type: :controller do

  include_context 'time helpers'

  describe 'GET #index' do
    it_behaves_like 'unauthenticated not allowed' do
      before do
        get :index
      end
    end

    it_behaves_like 'authenticated' do

      before do
        @platform_themes = create_list :platform_theme, 3
      end

      let :total_platform_themes do
        @platform_themes.length
      end

      let :platform_theme_ids do
        @platform_themes.map(&:friendly_id)
      end

      it 'should return a list of all platform themes' do
        get :index
        expect(response).to be_success
        expect(json_response.length).to eq total_platform_themes
        expect(pluck_from_json_response('id')).to match_array platform_theme_ids
      end

    end
  end

  describe 'GET #show' do
    before do
      @platform_theme = create :platform_theme
    end

    it_behaves_like 'unauthenticated not allowed'  do
      before do
        get :show, params: { id: @platform_theme.friendly_id }
      end
    end

    it_behaves_like 'authenticated' do

      context 'for a non-existent platform theme' do
        it 'should return a 404' do
          get :show, params: { id: 'unknown' }
          expect(response).to have_http_status(404)
        end
      end

      context 'for a platform theme that exists' do
        it 'should return the specified platform theme resource' do
          get :show, params: { id: @platform_theme.friendly_id }
          expect(response).to be_success
          expect(json_response).to eq({
            'id' => @platform_theme.friendly_id,
            'title' => @platform_theme.title,
            'description' => @platform_theme.description,
            'image_url' => @platform_theme.image_url,
            'colour' => @platform_theme.colour,
            'resources' => @platform_theme.resources,
            'created_at' => now_json_value,
            'updated_at' => now_json_value
          })
        end
      end

    end
  end

  describe 'POST #create' do
    let :post_data do
      source_data = build :platform_theme

      {
        platform_theme: {
          title: source_data.title,
          description: source_data.description,
          image_url: source_data.image_url,
          colour: source_data.colour,
          resources: source_data.resources
        }
      }
    end

    it_behaves_like 'unauthenticated not allowed'  do
      before do
        post :create, params: post_data
      end
    end

    it_behaves_like 'authenticated' do

      it_behaves_like 'not an admin so forbidden'  do
        before do
          post :create, params: post_data
        end
      end

      it_behaves_like 'an admin' do

        it 'creates a new platform theme as expected' do
          expect(PlatformTheme.count).to eq 0
          expect(Audit.count).to eq 0
          post :create, params: post_data
          expect(response).to be_success
          expect(PlatformTheme.count).to eq 1
          platform_theme = PlatformTheme.first
          new_platform_theme_external_id = platform_theme.friendly_id
          new_platform_theme_internal_id = platform_theme.id
          expect(json_response).to eq({
            'id' => new_platform_theme_external_id,
            'title' => post_data[:platform_theme][:title],
            'description' => post_data[:platform_theme][:description],
            'image_url' => post_data[:platform_theme][:image_url],
            'colour' => post_data[:platform_theme][:colour],
            'resources' => post_data[:platform_theme][:resources],
            'created_at' => now_json_value,
            'updated_at' => now_json_value
          });
          expect(Audit.count).to eq 1
          audit = Audit.first
          expect(audit.action).to eq 'create'
          expect(audit.auditable.id).to eq new_platform_theme_internal_id
          expect(audit.user.id).to eq current_user_id
        end

      end

    end
  end

  describe 'PUT #update' do
    let :put_data do
      {
        id: @platform_theme.friendly_id,
        platform_theme: {
          description: @platform_theme.description + 'foobar',
          colour: 'this is a new colour'
        }
      }
    end

    before do
      @platform_theme = create :platform_theme
    end

    it_behaves_like 'unauthenticated not allowed'  do
      before do
        put :update, params: put_data
      end
    end

    it_behaves_like 'authenticated' do

      it_behaves_like 'not an admin so forbidden'  do
        before do
          put :update, params: put_data
        end
      end

      it_behaves_like 'an admin' do

        it 'updates the specified platform theme' do
          expect(PlatformTheme.count).to eq 1
          expect(Audit.count).to eq 0
          put :update, params: put_data
          expect(response).to be_success
          expect(PlatformTheme.count).to eq 1
          updated = PlatformTheme.first
          expect(updated.title).to eq @platform_theme.title
          expect(updated.description).to eq put_data[:platform_theme][:description]
          expect(updated.colour).to eq put_data[:platform_theme][:colour]
          expect(Audit.count).to eq 1
          audit = Audit.first
          expect(audit.action).to eq 'update'
          expect(audit.auditable.id).to eq @platform_theme.id
          expect(audit.user.id).to eq current_user_id
        end

      end

    end
  end

  describe 'DELETE #destroy' do
    before do
      @platform_theme = create :platform_theme
    end

    it_behaves_like 'unauthenticated not allowed'  do
      before do
        delete :destroy, params: { id: @platform_theme.id }
      end
    end

    it_behaves_like 'authenticated' do

      it_behaves_like 'not an admin so forbidden'  do
        before do
          delete :destroy, params: { id: @platform_theme.id }
        end
      end

      it_behaves_like 'an admin' do

        it 'should delete the specified platform theme' do
          expect(PlatformTheme.exists?(@platform_theme.id)).to be true
          expect(Audit.count).to eq 0
          delete :destroy, params: { id: @platform_theme.id }
          expect(response).to be_success
          expect(PlatformTheme.exists?(@platform_theme.id)).to be false
          expect(Audit.count).to eq 1
          audit = Audit.first
          expect(audit.action).to eq 'destroy'
          expect(audit.user.id).to eq current_user_id
        end

      end

    end
  end

end
