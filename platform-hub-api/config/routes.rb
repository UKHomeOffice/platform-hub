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

      resources :services
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
      constraints: { id: ContactList::ID_REGEX_FOR_ROUTES }

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

        resources :tokens do
          patch '/escalate', to: 'tokens#escalate', on: :member
          patch '/deescalate', to: 'tokens#deescalate', on: :member
        end

        resources :clusters, except: :destroy

        get '/changeset/:cluster', to: 'changeset#index'

        post '/sync', to: 'sync#sync'
        post '/revoke', to: 'revoke#revoke'

        resources :groups do
          get :privileged, on: :collection
          post :allocate, on: :member
        end
      end
    end
  end

end
