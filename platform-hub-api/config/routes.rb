Rails.application.routes.draw do

  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html

  scope :format => false do

    root to: 'root#index'

    get '/healthz', to: 'healthcheck#show'

    get '/me', to: 'me#show'
    post '/me/agree_terms_of_service', to: 'me#agree_terms_of_service'
    post '/me/complete_hub_onboarding', to: 'me#complete_hub_onboarding'
    post '/me/complete_services_onboarding', to: 'me#complete_services_onboarding'
    post '/me/global_announcements/mark_all_read', to: 'me#global_announcements_mark_all_read'

    resources :feature_flags, only: [ :index ] do
      put '/:flag', to: 'feature_flags#update_flag', on: :collection
    end

    constraints service: /kubernetes/ do
      delete '/me/identities/:service', to: 'me#delete_identity'
    end

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

      get :identities, on: :member

      post :make_admin, on: :member
      post :revoke_admin, on: :member

      post :activate, on: :member
      post :deactivate, on: :member

      post :onboard_github, on: :member
      post :offboard_github, on: :member
    end

    resources :projects, constraints: lambda { |request| FeatureFlagService.is_enabled?(:projects) } do
      get '/memberships', to: 'projects#memberships', on: :member
      put '/memberships/:user_id', to: 'projects#add_membership', on: :member
      delete '/memberships/:user_id', to: 'projects#remove_membership', on: :member

      constraints lambda { |request| ProjectMembership.roles.keys.include?(request.params[:role]) } do
        put '/memberships/:user_id/role/:role', to: 'projects#set_role', on: :member
        delete '/memberships/:user_id/role/:role', to: 'projects#unset_role', on: :member
      end
    end

    resources :support_request_templates do
      get :form_field_types, on: :collection
      get :git_hub_repos, on: :collection
    end

    resources :support_requests, only: [ :create ]

    resources :platform_themes

    resource :app_settings, only: [ :show, :update ]

    resources :contact_lists,
      except: [ :create ],
      constraints: { id: ContactList::ID_REGEX }

    resources :announcement_templates do
      get :form_field_types, on: :collection
      post :preview, on: :collection
    end

    resources :announcements do
      get :global, on: :collection
      post :mark_sticky, on: :member
      post :unmark_sticky, on: :member
      post :resend, on: :member
    end

    constraints lambda { |request| FeatureFlagService.is_enabled?(:kubernetes_tokens) } do
      namespace :kubernetes do
        # Tokens management
        get '/tokens/:user_id', to: 'tokens#index'
        put '/tokens/:user_id/:cluster', to: 'tokens#create_or_update'
        patch '/tokens/:user_id/:cluster', to: 'tokens#create_or_update'
        delete '/tokens/:user_id/:cluster', to: 'tokens#destroy'
        post '/tokens/:user_id/:cluster/escalate', to: 'tokens#escalate'

        get '/robot_tokens/:cluster', to: 'robot_tokens#index'
        put '/robot_tokens/:cluster/:name', to: 'robot_tokens#create_or_update'
        patch '/robot_tokens/:cluster/:name', to: 'robot_tokens#create_or_update'
        delete '/robot_tokens/:cluster/:name', to: 'robot_tokens#destroy'

        get '/clusters', to: 'clusters#index'
        put '/clusters/:id', to: 'clusters#create_or_update'
        patch '/clusters/:id', to: 'clusters#create_or_update'

        get '/changeset/:cluster', to: 'changeset#index'

        post '/sync', to: 'sync#sync'
        post '/claim', to: 'claim#claim'
        post '/revoke', to: 'revoke#revoke'

        get '/groups/privileged', to: 'groups#privileged'
      end
    end
  end

end
