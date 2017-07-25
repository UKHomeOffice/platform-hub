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
        @a1 = create :announcement, is_global: true, publish_at: (now - 1.second)
        @a2 = create :announcement, is_global: true, publish_at: (now + 1.hour)
        @a3 = create :announcement, is_global: false, publish_at: (now + 1.hour)
        @a4 = create :announcement, is_global: true, publish_at: (now - 1.hour)
        @a5 = create :announcement, is_global: false, publish_at: (now - 1.hour)
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
            'original_template_id' => nil,
            'template_data' => nil,
            'title' => @announcement.title,
            'text' => @announcement.text,
            'is_global' => @announcement.is_global,
            'is_sticky' => @announcement.is_sticky,
            'publish_at' => @announcement.publish_at.iso8601,
            'created_at' => now_json_value,
            'updated_at' => now_json_value
          })
        end
      end

    end
  end

  describe 'POST #create' do
    let :post_data do
      {}
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

        context 'for an announcement with provided content' do
          let :post_data do
            source_data = build :announcement

            {
              announcement: {
                level: 'critical',
                title: source_data.title,
                text: source_data.text,
                is_global: source_data.is_global,
                is_sticky: source_data.is_sticky,
                publish_at: source_data.publish_at,
                deliver_to: source_data.deliver_to
              }
            }
          end

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
              'original_template_id' => nil,
              'template_data' => nil,
              'title' => post_data[:announcement][:title],
              'text' => post_data[:announcement][:text],
              'is_global' => post_data[:announcement][:is_global],
              'is_sticky' => post_data[:announcement][:is_sticky],
              'publish_at' => post_data[:announcement][:publish_at].iso8601,
              'created_at' => now_json_value,
              'updated_at' => now_json_value,
              'deliver_to' => post_data[:announcement][:deliver_to],
              'status' => 'awaiting_delivery'
            });
            expect(Audit.count).to eq 1
            audit = Audit.first
            expect(audit.action).to eq 'create'
            expect(audit.auditable.id).to eq new_announcement_id
            expect(audit.user.id).to eq current_user_id
          end
        end

        context 'for a template based announcement with provided template data' do
          let :post_data do
            @source_data = build :announcement_from_template

            {
              announcement: {
                level: 'info',
                original_template_id: @source_data.original_template.id,
                template_data: @source_data.template_data,
                is_global: @source_data.is_global,
                is_sticky: @source_data.is_sticky,
                publish_at: @source_data.publish_at,
                deliver_to: @source_data.deliver_to
              }
            }
          end

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
              'original_template_id' => post_data[:announcement][:original_template_id],
              'template_data' => post_data[:announcement][:template_data],
              'title' => nil,
              'text' => nil,
              'is_global' => post_data[:announcement][:is_global],
              'is_sticky' => post_data[:announcement][:is_sticky],
              'publish_at' => post_data[:announcement][:publish_at].iso8601,
              'created_at' => now_json_value,
              'updated_at' => now_json_value,
              'deliver_to' => post_data[:announcement][:deliver_to],
              'status' => 'awaiting_delivery',
              'preview' => Hashie::Mash.new(AnnouncementTemplateFormatterService.format(@source_data.original_template.spec['templates'], post_data[:announcement][:template_data]))
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
  end

  describe 'PUT #update' do
    let :put_data do
      {
        id: @announcement.id,
        announcement: {
          level: 'critical',
          text: @announcement.text + ' foobar',
          is_sticky: !@announcement.is_sticky,
          publish_at: now + 100.hours
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
            expect(updated.publish_at).to eq put_data[:announcement][:publish_at].iso8601
            expect(Audit.count).to eq 1
            audit = Audit.first
            expect(audit.action).to eq 'update'
            expect(audit.auditable.id).to eq @announcement.id
            expect(audit.user.id).to eq current_user_id
          end
        end

        context 'for a readonly announcement' do
          before do
            @readonly_announcement = create :readonly_announcement
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

        context 'updating the template for a template based announcement' do
          before do
            @announcement_from_template = create :announcement_from_template
            @new_template = create :announcement_template, fields_count: (@announcement_from_template.original_template.spec['fields'].length + 1)
          end

          let :put_data do
            {
              id: @announcement_from_template.id,
              announcement: {
                level: 'critical',
                original_template_id: @new_template.id,
                template_data: @new_template.spec['fields'].each_with_object({}) do |f, obj|
                  id = f['id']
                  obj[id] = "#{id} value"
                end
              }
            }
          end

          it 'updates the specified announcement' do
            expect(Audit.count).to eq 0
            put :update, params: put_data
            expect(response).to be_success
            updated = Announcement.find @announcement_from_template.id
            expect(updated.level).to eq put_data[:announcement][:level]
            expect(updated.original_template).to eq @new_template
            expect(updated.template_definitions).to eq @new_template.spec['templates']
            expect(updated.template_data).to eq put_data[:announcement][:template_data]
            expect(updated.title).to eq nil
            expect(updated.text).to eq nil
            expect(updated.is_global).to eq @announcement_from_template.is_global
            expect(updated.is_sticky).to eq @announcement_from_template.is_sticky
            expect(updated.publish_at.iso8601).to eq @announcement_from_template.publish_at.iso8601
            expect(Audit.count).to eq 1
            audit = Audit.first
            expect(audit.action).to eq 'update'
            expect(audit.auditable.id).to eq @announcement_from_template.id
            expect(audit.user.id).to eq current_user_id
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

        context 'for non readonly announcement' do
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

        context 'for a readonly announcement' do
          before do
            @readonly_announcement = create :readonly_announcement
          end

          it 'should delete the specified announcement' do
            expect(Announcement.exists?(@readonly_announcement.id)).to be true
            expect(Audit.count).to eq 0
            delete :destroy, params: { id: @readonly_announcement.id }
            expect(response).to be_success
            expect(Announcement.exists?(@readonly_announcement.id)).to be false
            expect(Audit.count).to eq 1
            audit = Audit.first
            expect(audit.action).to eq 'destroy'
            expect(audit.user.id).to eq current_user_id
          end
        end

      end

    end
  end

  describe 'POST #mark_sticky' do
    before do
      @announcement = create :announcement, is_sticky: false
    end

    it_behaves_like 'unauthenticated not allowed'  do
      before do
        post :mark_sticky, params: { id: @announcement.id }
      end
    end

    it_behaves_like 'authenticated' do

      it_behaves_like 'not an admin so forbidden'  do
        before do
          get :mark_sticky, params: { id: @announcement.id }
        end
      end

      it_behaves_like 'an admin' do

        it 'should mark the specified announcement as sticky' do
          expect(@announcement.is_sticky).to be false
          expect(Audit.count).to eq 0
          get :mark_sticky, params: { id: @announcement.id }
          expect(response).to be_success
          expect(@announcement.reload.is_sticky).to be true
          expect(Audit.count).to eq 1
          audit = Audit.first
          expect(audit.action).to eq 'mark_sticky'
          expect(audit.auditable).to eq @announcement
          expect(audit.user.id).to eq current_user_id
        end

      end

    end
  end

  describe 'POST #unmark_sticky' do
    before do
      @announcement = create :announcement, is_sticky: true
    end

    it_behaves_like 'unauthenticated not allowed'  do
      before do
        post :unmark_sticky, params: { id: @announcement.id }
      end
    end

    it_behaves_like 'authenticated' do

      it_behaves_like 'not an admin so forbidden'  do
        before do
          get :unmark_sticky, params: { id: @announcement.id }
        end
      end

      it_behaves_like 'an admin' do

        it 'should unmark the specified announcement as sticky' do
          expect(@announcement.is_sticky).to be true
          expect(Audit.count).to eq 0
          get :unmark_sticky, params: { id: @announcement.id }
          expect(response).to be_success
          expect(@announcement.reload.is_sticky).to be false
          expect(Audit.count).to eq 1
          audit = Audit.first
          expect(audit.action).to eq 'unmark_sticky'
          expect(audit.auditable).to eq @announcement
          expect(audit.user.id).to eq current_user_id
        end

      end

    end
  end

end
