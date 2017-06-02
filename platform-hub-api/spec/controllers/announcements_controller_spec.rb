require 'rails_helper'

RSpec.describe AnnouncementsController, type: :controller do

  include_context 'time helpers'

  describe 'GET #index' do
    it_behaves_like 'unauthenticated not allowed' do
      before do
        get :index
      end
    end

    it_behaves_like 'authenticated' do

      it_behaves_like 'not an admin so forbidden'  do
        before do
          get :index
        end
      end

      it_behaves_like 'an admin' do

        before do
          @announcements = create_list :announcement, 3
        end

        let :total_announcements do
          @announcements.length
        end

        let :announcement_ids do
          @announcements.map(&:id)
        end

        it 'should return a list of all announcements' do
          get :index
          expect(response).to be_success
          expect(json_response.length).to eq total_announcements
          expect(pluck_from_json_response('id')).to match_array announcement_ids
        end

      end

    end
  end

  describe 'GET #global' do
    it_behaves_like 'unauthenticated not allowed' do
      before do
        get :global
      end
    end

    it_behaves_like 'authenticated' do

      before do
        @a1 = create :announcement, is_global: true, published_at: (now - 1.second)
        @a2 = create :announcement, is_global: true, published_at: (now + 1.hour)
        @a3 = create :announcement, is_global: false, published_at: (now + 1.hour)
        @a4 = create :announcement, is_global: true, published_at: (now - 1.hour)
        @a5 = create :announcement, is_global: false, published_at: (now - 1.hour)
      end

      it 'should return a list of global and published announcements only and ordered by published date (desc)' do
        get :global
        expect(response).to be_success
        expect(json_response.length).to eq 2
        expect(pluck_from_json_response('id')).to match_array [@a1.id, @a4.id]
      end

    end
  end

  describe 'GET #show' do
    before do
      @announcement = create :announcement
    end

    it_behaves_like 'unauthenticated not allowed'  do
      before do
        get :show, params: { id: @announcement.id }
      end
    end

    it_behaves_like 'authenticated' do

      context 'for a non-existent announcement' do
        it 'should return a 404' do
          get :show, params: { id: 'unknown' }
          expect(response).to have_http_status(404)
        end
      end

      context 'for a announcement that exists' do
        it 'should return the specified announcement resource' do
          get :show, params: { id: @announcement.id }
          expect(response).to be_success
          expect(json_response).to eq({
            'id' => @announcement.id,
            'level' => 'info',
            'title' => @announcement.title,
            'text' => @announcement.text,
            'is_global' => @announcement.is_global,
            'is_sticky' => @announcement.is_sticky,
            'published_at' => @announcement.published_at.iso8601,
            'created_at' => now_json_value,
            'updated_at' => now_json_value
          })
        end
      end

    end
  end

  describe 'POST #create' do
    let :post_data do
      source_data = build :announcement

      {
        announcement: {
          level: 'critical',
          title: source_data.title,
          text: source_data.text,
          is_global: source_data.is_global,
          is_sticky: source_data.is_sticky,
          published_at: source_data.published_at,
          deliver_to: source_data.deliver_to
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

        it 'creates a new announcement as expected' do
          expect(Announcement.count).to eq 0
          expect(Audit.count).to eq 0
          post :create, params: post_data
          expect(response).to be_success
          expect(Announcement.count).to eq 1
          announcement = Announcement.first
          new_announcement_id = announcement.id
          expect(json_response).to eq({
            'id' => new_announcement_id,
            'level' => post_data[:announcement][:level],
            'title' => post_data[:announcement][:title],
            'text' => post_data[:announcement][:text],
            'is_global' => post_data[:announcement][:is_global],
            'is_sticky' => post_data[:announcement][:is_sticky],
            'published_at' => post_data[:announcement][:published_at].iso8601,
            'created_at' => now_json_value,
            'updated_at' => now_json_value,
            'deliver_to' => post_data[:announcement][:deliver_to],
            'status' => 'waiting_delivery'
          });
          expect(Audit.count).to eq 1
          audit = Audit.first
          expect(audit.action).to eq 'create'
          expect(audit.auditable.id).to eq new_announcement_id
          expect(audit.user.id).to eq current_user_id
        end

      end

    end
  end

  describe 'PUT #update' do
    let :put_data do
      {
        id: @announcement.id,
        announcement: {
          level: 'critical',
          text: @announcement.text + ' foobar',
          is_sticky: !@announcement.is_sticky,
          published_at: now + 100.hours
        }
      }
    end

    before do
      @announcement = create :announcement
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

        context 'for non readonly announcement' do
          it 'updates the specified announcement' do
            expect(Announcement.count).to eq 1
            expect(Audit.count).to eq 0
            put :update, params: put_data
            expect(response).to be_success
            expect(Announcement.count).to eq 1
            updated = Announcement.first
            expect(updated.level).to eq put_data[:announcement][:level]
            expect(updated.title).to eq @announcement.title
            expect(updated.text).to eq put_data[:announcement][:text]
            expect(updated.is_global).to eq @announcement.is_global
            expect(updated.is_sticky).to eq put_data[:announcement][:is_sticky]
            expect(updated.published_at).to eq put_data[:announcement][:published_at].iso8601
            expect(Audit.count).to eq 1
            audit = Audit.first
            expect(audit.action).to eq 'update'
            expect(audit.auditable.id).to eq @announcement.id
            expect(audit.user.id).to eq current_user_id
          end
        end

        context 'for a readonly announcement' do
          before do
            @readonly_announcement = create :announcement, status: :delivering
          end

          it 'returns an appropriate error and does not update the announcement' do
            put :update, params: {
              id: @readonly_announcement.id,
              announcement: {
                level: 'critical',
                title: 'new_title'
              }
            }
            expect(response).to have_http_status 422
            expect(json_response['error']['message']).to eq 'Resource is readonly'
            existing = Announcement.find(@readonly_announcement.id)
            expect(existing).to eq @readonly_announcement
          end
        end

      end

    end
  end

  describe 'DELETE #destroy' do
    before do
      @announcement = create :announcement
    end

    it_behaves_like 'unauthenticated not allowed'  do
      before do
        delete :destroy, params: { id: @announcement.id }
      end
    end

    it_behaves_like 'authenticated' do

      it_behaves_like 'not an admin so forbidden'  do
        before do
          delete :destroy, params: { id: @announcement.id }
        end
      end

      it_behaves_like 'an admin' do

        it 'should delete the specified announcement' do
          expect(Announcement.exists?(@announcement.id)).to be true
          expect(Audit.count).to eq 0
          delete :destroy, params: { id: @announcement.id }
          expect(response).to be_success
          expect(Announcement.exists?(@announcement.id)).to be false
          expect(Audit.count).to eq 1
          audit = Audit.first
          expect(audit.action).to eq 'destroy'
          expect(audit.user.id).to eq current_user_id
        end

      end

    end
  end

end
