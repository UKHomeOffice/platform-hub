require 'rails_helper'

RSpec.describe AnnouncementTemplatesController, type: :controller do

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
          @announcement_templates = create_list :announcement_template, 3
        end

        let :total_announcement_templates do
          @announcement_templates.length
        end

        let :announcement_template_ids do
          @announcement_templates.sort_by(&:shortname).map(&:friendly_id)
        end

        it 'should return a list of all announcement templates' do
          get :index
          expect(response).to be_success
          expect(json_response.length).to eq total_announcement_templates
          expect(pluck_from_json_response('id')).to eq announcement_template_ids
        end

      end

    end
  end

  describe 'GET #show' do
    before do
      @announcement_template = create :announcement_template
    end

    it_behaves_like 'unauthenticated not allowed'  do
      before do
        get :show, params: { id: @announcement_template.friendly_id }
      end
    end

    it_behaves_like 'authenticated' do

      it_behaves_like 'not an admin so forbidden'  do
        before do
          get :show, params: { id: @announcement_template.friendly_id }
        end
      end

      it_behaves_like 'an admin' do

        context 'for a non-existent announcement template' do
          it 'should return a 404' do
            get :show, params: { id: 'unknown' }
            expect(response).to have_http_status(404)
          end
        end

        context 'for a announcement template that exists' do
          it 'should return the specified announcement template resource' do
            get :show, params: { id: @announcement_template.friendly_id }
            expect(response).to be_success
            expect(json_response).to eq({
              'id' => @announcement_template.friendly_id,
              'shortname' => @announcement_template.shortname,
              'description' => @announcement_template.description,
              'spec' => Hashie::Mash.new(@announcement_template.spec),
              'created_at' => now_json_value,
              'updated_at' => now_json_value,
            })
          end
        end

      end

    end
  end

  describe 'POST #create' do
    let :post_data do
      source_data = build :announcement_template

      {
        announcement_template: {
          shortname: source_data.shortname,
          description: source_data.description,
          spec: source_data.spec
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

        it 'creates a new announcement template as expected' do
          expect(AnnouncementTemplate.count).to eq 0
          expect(Audit.count).to eq 0
          post :create, params: post_data
          expect(response).to be_success
          expect(AnnouncementTemplate.count).to eq 1
          announcement_template = AnnouncementTemplate.first
          announcement_template_external_id = announcement_template.friendly_id
          announcement_template_internal_id = announcement_template.id
          expect(json_response).to eq({
            'id' => announcement_template_external_id,
            'shortname' => post_data[:announcement_template][:shortname],
            'description' => post_data[:announcement_template][:description],
            'spec' => Hashie::Mash.new(post_data[:announcement_template][:spec]),
            'created_at' => now_json_value,
            'updated_at' => now_json_value
          });
          expect(Audit.count).to eq 1
          audit = Audit.first
          expect(audit.action).to eq 'create'
          expect(audit.auditable.id).to eq announcement_template_internal_id
          expect(audit.user.id).to eq current_user_id
        end

      end

    end
  end

  describe 'PUT #update' do
    let :put_data do
      {
        id: @announcement_template.friendly_id,
        announcement_template: {
          shortname: 'foo'
        }
      }
    end

    before do
      @announcement_template = create :announcement_template
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

        it 'updates the specified announcement template' do
          expect(AnnouncementTemplate.count).to eq 1
          expect(Audit.count).to eq 0
          put :update, params: put_data
          expect(response).to be_success
          expect(AnnouncementTemplate.count).to eq 1
          updated = AnnouncementTemplate.first
          expect(updated.shortname).to eq put_data[:announcement_template][:shortname]
          expect(updated.description).to eq @announcement_template.description
          expect(updated.spec).to eq Hashie::Mash.new(@announcement_template.spec)
          expect(Audit.count).to eq 1
          audit = Audit.first
          expect(audit.action).to eq 'update'
          expect(audit.auditable.id).to eq @announcement_template.id
          expect(audit.user.id).to eq current_user_id
        end

      end

    end
  end

  describe 'DELETE #destroy' do
    before do
      @announcement_template = create :announcement_template
    end

    it_behaves_like 'unauthenticated not allowed'  do
      before do
        delete :destroy, params: { id: @announcement_template.id }
      end
    end

    it_behaves_like 'authenticated' do

      it_behaves_like 'not an admin so forbidden'  do
        before do
          delete :destroy, params: { id: @announcement_template.id }
        end
      end

      it_behaves_like 'an admin' do

        it 'should delete the specified announcement template' do
          expect(AnnouncementTemplate.exists?(@announcement_template.id)).to be true
          expect(Audit.count).to eq 0
          delete :destroy, params: { id: @announcement_template.id }
          expect(response).to be_success
          expect(AnnouncementTemplate.exists?(@announcement_template.id)).to be false
          expect(Audit.count).to eq 1
          audit = Audit.first
          expect(audit.action).to eq 'destroy'
          expect(audit.user.id).to eq current_user_id
        end

      end

    end
  end

  describe 'GET #form_field_types' do
    it_behaves_like 'unauthenticated not allowed' do
      before do
        get :form_field_types
      end
    end

    it_behaves_like 'authenticated' do

      it_behaves_like 'not an admin so forbidden'  do
        before do
          get :form_field_types
        end
      end

      it_behaves_like 'an admin' do
        it 'should return the available form field types' do
          get :form_field_types
          expect(response).to be_success
          expect(json_response).to eq AnnouncementTemplate.form_field_types.to_a
        end
      end

    end
  end

end
