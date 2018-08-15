require "rails_helper"

RSpec.describe DocsSourcesController, type: :routing do
  describe "routing" do

    it "routes to #index" do
      expect(:get => "/docs_sources").to route_to("docs_sources#index")
    end

    it "routes to #show" do
      expect(:get => "/docs_sources/1").to route_to("docs_sources#show", :id => "1")
    end

    it "routes to #create" do
      expect(:post => "/docs_sources").to route_to("docs_sources#create")
    end

    it "routes to #update via PUT" do
      expect(:put => "/docs_sources/1").to route_to("docs_sources#update", :id => "1")
    end

    it "routes to #update via PATCH" do
      expect(:patch => "/docs_sources/1").to route_to("docs_sources#update", :id => "1")
    end

    it "routes to #destroy" do
      expect(:delete => "/docs_sources/1").to route_to("docs_sources#destroy", :id => "1")
    end

  end
end
