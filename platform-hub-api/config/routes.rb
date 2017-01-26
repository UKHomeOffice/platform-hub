Rails.application.routes.draw do
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html

  scope :format => false do

    root to: 'root#index'

    get '/healthz', to: 'healthcheck#show'

    get '/me', to: 'me#show'

    constraints service: /github/ do

      delete '/me/identities/:service', to: 'me#delete_identity'

      get '/identity_flows/start/:service',
        to: 'identity_flows#start_auth_flow',
        as: 'identity_flows_start'

      get '/identity_flows/callback/:service',
        to: 'identity_flows#callback',
        as: 'identity_flows_callback'

    end

    resources :users, only: [ :index, :show ] do
      get '/search/:q', to: 'users#search', on: :collection

      post :make_admin, on: :member
      post :revoke_admin, on: :member
    end

    resources :projects do
      get '/memberships', to: 'projects#memberships', :on => :member
      put '/memberships/:user_id', to: 'projects#add_membership', :on => :member
      delete '/memberships/:user_id', to: 'projects#remove_membership', :on => :member
    end

  end

end
