require 'rails_helper'

RSpec.describe SupportRequestsController, type: :controller do

  describe 'POST #create' do
    it_behaves_like 'unauthenticated not allowed' do
      before do
        post :create
      end
    end

    it_behaves_like 'authenticated' do

      before do
        @template = create :support_request_template
      end

      context 'with no data provided' do
        let :post_data do
          {
            template_id: @template.friendly_id,
            data: {}
          }
        end

        it 'should return an HTTP 422' do
          post :create, params: post_data
          expect(response).to have_http_status(422)
        end
      end

      context 'with data provided' do
        let :post_data do
          {
            template_id: @template.friendly_id,
            data: {
              aKey: 'aValue'
            }
          }
        end

        let(:git_hub_agent_service) { double :git_hub_agent_service }

        let(:title) { 'title' }

        let(:body) { 'body' }

        let(:url) { 'http://example.com' }

        let :formatted_result do
          instance_double 'SupportRequestFormatterService::Result', title: title, body: body
        end

        before do
          allow(@controller).to receive(:git_hub_agent_service).and_return(git_hub_agent_service)
        end

        it 'should format a support request from the data provided and submit this via the GitHub agent service' do
          expect(SupportRequestFormatterService).to receive(:format)
            .with(@template, ActionController::Parameters.new(post_data[:data]), current_user)
            .and_return(formatted_result)

          expect(git_hub_agent_service).to receive(:create_issue)
            .with(@template.git_hub_repo, title, body)
            .and_return(url)

          expect(Audit.count).to be 0
          post :create, params: post_data
          expect(response).to be_success
          expect(Audit.count).to be 1
          audit = Audit.first
          expect(audit.action).to eq 'create_request_from'
          expect(audit.auditable.id).to eq @template.id
          expect(audit.user.id).to eq current_user_id
          expect(audit.comment).to eq "GitHub issue: #{url}"
        end
      end

    end
  end

end
