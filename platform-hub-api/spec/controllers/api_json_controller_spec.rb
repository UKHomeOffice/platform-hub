require 'rails_helper'

RSpec.describe ApiJsonController, type: :controller do

  controller(ApiJsonController) do
    def index
      head :no_content
    end
  end

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
