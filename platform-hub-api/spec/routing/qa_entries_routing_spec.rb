require "rails_helper"

RSpec.describe QaEntriesController, type: :routing do
  describe "routing" do

    it "routes to #index" do
      expect(:get => "/qa_entries").to route_to("qa_entries#index")
    end

    it "routes to #show" do
      expect(:get => "/qa_entries/1").to route_to("qa_entries#show", :id => "1")
    end

    it "routes to #create" do
      expect(:post => "/qa_entries").to route_to("qa_entries#create")
    end

    it "routes to #update via PUT" do
      expect(:put => "/qa_entries/1").to route_to("qa_entries#update", :id => "1")
    end

    it "routes to #update via PATCH" do
      expect(:patch => "/qa_entries/1").to route_to("qa_entries#update", :id => "1")
    end

    it "routes to #destroy" do
      expect(:delete => "/qa_entries/1").to route_to("qa_entries#destroy", :id => "1")
    end

  end
end
