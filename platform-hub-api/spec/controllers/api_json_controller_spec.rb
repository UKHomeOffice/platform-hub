require 'rails_helper'

RSpec.describe ApiJsonController, type: :controller do

  controller(ApiJsonController) do
    skip_authorization_check only: :index
    authorize_resource except: :index, class: false

    def index
      head :no_content
    end

    def show
      render json: {}
    end
  end

  context 'for an authenticated only endpoint (no authorization needed)' do

    it_behaves_like 'unauthenticated not allowed'  do
      before do
        get :index
      end
    end

    it_behaves_like 'authenticated' do

      context 'when not requesting JSON' do
        before do
          @request.set_header 'HTTP_ACCEPT', 'text/plain'
        end

        it 'should return a 406 Not Acceptable' do
          get :index
          expect(response).to have_http_status(406)
        end
      end

      context 'when requesting JSON' do
        it 'should serve request as expected' do
          get :index
          expect(response).to have_http_status(204)
        end
      end

    end

  end

  context 'for an authenticated and admin only endpoint' do

    it_behaves_like 'unauthenticated not allowed'  do
      before do
        get :show, params: { id: 'foo' }
      end
    end

    it_behaves_like 'authenticated' do

      it_behaves_like 'not a hub admin so forbidden'  do
        before do
          get :show, params: { id: 'foo' }
        end
      end

      it_behaves_like 'a hub admin' do

        context 'when not requesting JSON' do
          before do
            @request.set_header 'HTTP_ACCEPT', 'text/plain'
          end

          it 'should return a 406 Not Acceptable' do
            get :show, params: { id: 'foo' }
            expect(response).to have_http_status(406)
          end
        end

        context 'when requesting JSON' do
          it 'should serve request as expected' do
            get :show, params: { id: 'foo' }
            expect(response).to be_success
            expect(json_response).to eq({})
          end
        end

      end

    end

  end

end
