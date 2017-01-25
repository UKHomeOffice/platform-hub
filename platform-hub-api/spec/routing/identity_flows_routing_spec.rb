require 'rails_helper'

describe '/identity_flows routing', type: :routing do

  it 'should route as expected for an allowed service' do
    expect(:get => '/identity_flows/start/github').to route_to(
      :controller => 'identity_flows',
      :action => 'start_auth_flow',
      :service => 'github'
    )
    expect(:get => '/identity_flows/callback/github').to route_to(
      :controller => 'identity_flows',
      :action => 'callback',
      :service => 'github'
    )
  end

  it 'should not route an unknown/unalllowed service' do
    expect(:get => '/identity_flows/start/no_good_service').not_to be_routable
    expect(:get => '/identity_flows/callback/no_good_service').not_to be_routable
  end

end
