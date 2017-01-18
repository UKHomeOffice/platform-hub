require 'rails_helper'

RSpec.describe RootController, type: :controller do

  describe "GET #index" do
    it_behaves_like 'not authenticated' do
      before do
        get :index
      end
    end

    it_behaves_like 'authenticated' do
      it "should return a 204 No Content" do
        get :index
        expect(response).to have_http_status(204)
      end
    end
  end

end
