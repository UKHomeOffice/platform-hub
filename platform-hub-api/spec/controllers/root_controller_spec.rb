require 'rails_helper'

RSpec.describe RootController, type: :controller do
  describe "GET #index" do
    it "responds successfully with an HTTP 204" do
      get :index
      expect(response).to be_success
      expect(response).to have_http_status(204)
    end
  end
end
