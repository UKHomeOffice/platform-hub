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

      post :onboard_github, on: :member
      post :offboard_github, on: :member
    end

    resources :projects do
      get '/memberships', to: 'projects#memberships', on: :member
      put '/memberships/:user_id', to: 'projects#add_membership', on: :member
      delete '/memberships/:user_id', to: 'projects#remove_membership', on: :member

      constraints lambda { |request| ProjectMembership.roles.keys.include?(request.params[:role]) } do
        put '/memberships/:user_id/role/:role', to: 'projects#set_role', on: :member
        delete '/memberships/:user_id/role/:role', to: 'projects#unset_role', on: :member
      end
    end

    resources :support_request_templates do
      get '/form_field_types', to: 'support_request_templates#form_field_types', on: :collection
    end

    resources :support_requests, only: [ :create ]

  end

end
