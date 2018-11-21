require "rails_helper"

RSpec.describe DockerReposController, type: :routing do
  describe "routing" do

    before do
      FeatureFlagService.create_or_update(:projects, true)
    end

    context 'with docker_repos feature flag enabled' do

      before do
        FeatureFlagService.create_or_update(:docker_repos, true)
      end

      it "routes to #index" do
        expect(:get => "/projects/foo/docker_repos").to route_to("docker_repos#index", :project_id => 'foo')
      end

      it "routes to #create" do
        expect(:post => "/projects/foo/docker_repos").to route_to("docker_repos#create", :project_id => 'foo')
      end

      it "routes to #destroy" do
        expect(:delete => "/projects/foo/docker_repos/1").to route_to("docker_repos#destroy", :project_id => 'foo', :id => "1")
      end

      it "routes to #update_access" do
        expect(:put => "/projects/foo/docker_repos/1/access").to route_to("docker_repos#update_access", :project_id => 'foo', :id => "1")
      end

    end

    context 'with docker_repos feature flag disabled' do

      before do
        FeatureFlagService.create_or_update(:docker_repos, false)
      end

      it "route to #index is not routable" do
        expect(:get => "/projects/foo/docker_repos").to_not be_routable
      end

      it "route to #create is not routable" do
        expect(:post => "/projects/foo/docker_repos").to_not be_routable
      end

      it "route to #destroy is not routable" do
        expect(:delete => "/projects/foo/docker_repos/1").to_not be_routable
      end

      it "route to #update_access is not routable" do
        expect(:put => "/projects/foo/docker_repos/1/access").to_not be_routable
      end

    end

  end
end
