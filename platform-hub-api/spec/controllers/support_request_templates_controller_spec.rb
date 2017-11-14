require 'rails_helper'

RSpec.describe SupportRequestTemplatesController, type: :controller do

  include_context 'time helpers'

  describe 'GET #index' do
    it_behaves_like 'unauthenticated not allowed' do
      before do
        get :index
      end
    end

    it_behaves_like 'authenticated' do

      before do
        @support_request_templates = create_list :support_request_template, 3
      end

      let :total_support_request_templates do
        @support_request_templates.length
      end

      let :support_request_template_ids do
        @support_request_templates.sort_by(&:title).map(&:friendly_id)
      end

      it 'should return a list of all support request templates' do
        get :index
        expect(response).to be_success
        expect(json_response.length).to eq total_support_request_templates
        expect(pluck_from_json_response('id')).to eq support_request_template_ids
      end

    end
  end

  describe 'GET #show' do
    before do
      @support_request_template = create :support_request_template
    end

    it_behaves_like 'unauthenticated not allowed'  do
      before do
        get :show, params: { id: @support_request_template.friendly_id }
      end
    end

    it_behaves_like 'authenticated' do

      context 'for a non-existent support request template' do
        it 'should return a 404' do
          get :show, params: { id: 'unknown' }
          expect(response).to have_http_status(404)
        end
      end

      context 'for a support request template that exists' do
        it 'should return the specified support request template resource' do
          get :show, params: { id: @support_request_template.friendly_id }
          expect(response).to be_success
          expect(json_response).to eq({
            'id' => @support_request_template.friendly_id,
            'shortname' => @support_request_template.shortname,
            'git_hub_repo' => @support_request_template.git_hub_repo,
            'title' => @support_request_template.title,
            'description' => @support_request_template.description,
            'form_spec' => Hashie::Mash.new(@support_request_template.form_spec),
            'git_hub_issue_spec' => Hashie::Mash.new(@support_request_template.git_hub_issue_spec),
            'user_scope' => nil,
            'created_at' => now_json_value,
            'updated_at' => now_json_value,
          })
        end
      end

    end
  end

  describe 'POST #create' do
    let :post_data do
      source_data = build :support_request_template

      {
        support_request_template: {
          shortname: source_data.shortname,
          git_hub_repo: source_data.git_hub_repo,
          title: source_data.title,
          description: source_data.description,
          form_spec: source_data.form_spec,
          git_hub_issue_spec: source_data.git_hub_issue_spec,
          user_scope: 'foo'
        }
      }
    end

    it_behaves_like 'unauthenticated not allowed'  do
      before do
        post :create, params: post_data
      end
    end

    it_behaves_like 'authenticated' do

      it_behaves_like 'not a hub admin so forbidden'  do
        before do
          post :create, params: post_data
        end
      end

      it_behaves_like 'a hub admin' do

        it 'creates a new support request template as expected' do
          expect(SupportRequestTemplate.count).to eq 0
          expect(Audit.count).to eq 0
          post :create, params: post_data
          expect(response).to be_success
          expect(SupportRequestTemplate.count).to eq 1
          support_request_template = SupportRequestTemplate.first
          new_support_request_template_external_id = support_request_template.friendly_id
          new_support_request_template_internal_id = support_request_template.id
          expect(json_response).to eq({
            'id' => new_support_request_template_external_id,
            'shortname' => post_data[:support_request_template][:shortname],
            'git_hub_repo' => post_data[:support_request_template][:git_hub_repo],
            'title' => post_data[:support_request_template][:title],
            'description' => post_data[:support_request_template][:description],
            'form_spec' => Hashie::Mash.new(post_data[:support_request_template][:form_spec]),
            'git_hub_issue_spec' => Hashie::Mash.new(post_data[:support_request_template][:git_hub_issue_spec]),
            'user_scope' => post_data[:support_request_template][:user_scope],
            'created_at' => now_json_value,
            'updated_at' => now_json_value
          });
          expect(Audit.count).to eq 1
          audit = Audit.first
          expect(audit.action).to eq 'create'
          expect(audit.auditable.id).to eq new_support_request_template_internal_id
          expect(audit.user.id).to eq current_user_id
        end

      end

    end
  end

  describe 'PUT #update' do
    let :put_data do
      {
        id: @support_request_template.friendly_id,
        support_request_template: {
          shortname: 'foo',
          title: 'foobar',
          form_spec: {
            help_text: 'No specific info is required for this form',
            fields: []
          },
          git_hub_issue_spec: @support_request_template.git_hub_issue_spec
        }
      }
    end

    before do
      @support_request_template = create :support_request_template
    end

    it_behaves_like 'unauthenticated not allowed'  do
      before do
        put :update, params: put_data
      end
    end

    it_behaves_like 'authenticated' do

      it_behaves_like 'not a hub admin so forbidden'  do
        before do
          put :update, params: put_data
        end
      end

      it_behaves_like 'a hub admin' do

        it 'updates the specified support request template' do
          expect(SupportRequestTemplate.count).to eq 1
          expect(Audit.count).to eq 0
          put :update, params: put_data
          expect(response).to be_success
          expect(SupportRequestTemplate.count).to eq 1
          updated = SupportRequestTemplate.first
          expect(updated.shortname).to eq put_data[:support_request_template][:shortname]
          expect(updated.title).to eq put_data[:support_request_template][:title]
          expect(updated.description).to eq @support_request_template.description
          expect(updated.form_spec).to eq Hashie::Mash.new(put_data[:support_request_template][:form_spec])
          expect(updated.git_hub_issue_spec).to eq @support_request_template.git_hub_issue_spec
          expect(Audit.count).to eq 1
          audit = Audit.first
          expect(audit.action).to eq 'update'
          expect(audit.auditable.id).to eq @support_request_template.id
          expect(audit.user.id).to eq current_user_id
        end

      end

    end
  end

  describe 'DELETE #destroy' do
    before do
      @support_request_template = create :support_request_template
    end

    it_behaves_like 'unauthenticated not allowed'  do
      before do
        delete :destroy, params: { id: @support_request_template.id }
      end
    end

    it_behaves_like 'authenticated' do

      it_behaves_like 'not a hub admin so forbidden'  do
        before do
          delete :destroy, params: { id: @support_request_template.id }
        end
      end

      it_behaves_like 'a hub admin' do

        it 'should delete the specified support request template' do
          expect(SupportRequestTemplate.exists?(@support_request_template.id)).to be true
          expect(Audit.count).to eq 0
          delete :destroy, params: { id: @support_request_template.id }
          expect(response).to be_success
          expect(SupportRequestTemplate.exists?(@support_request_template.id)).to be false
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

      it 'should return the available form field types' do
        get :form_field_types
        expect(response).to be_success
        expect(json_response).to eq SupportRequestTemplate.form_field_types.to_a
      end

    end
  end

  describe 'GET #git_hub_repos' do
    it_behaves_like 'unauthenticated not allowed' do
      before do
        get :git_hub_repos
      end
    end

    it_behaves_like 'authenticated' do

      let(:foo_repo) { 'http://example.com/foo' }
      let(:bar_repo) { 'http://example.com/bar' }

      before do
        create :support_request_template, :git_hub_repo => foo_repo
        create :support_request_template, :git_hub_repo => bar_repo
        create :support_request_template, :git_hub_repo => foo_repo
      end

      it 'should return a unique and sorted list of the possible GitHub repo URLs' do
        get :git_hub_repos
        expect(response).to be_success
        expect(json_response).to eq [ bar_repo, foo_repo ]
      end

    end
  end

end
