Rails.application.routes.draw do
  draw :madmin
  # Authentication routes
  get "/signin", to: "sessions#new", as: :signin
  post "/signin", to: "sessions#create"
  delete "/signout", to: "sessions#destroy", as: :signout

  get "/signup", to: "registrations#new", as: :signup
  post "/signup", to: "registrations#create"

  # Password reset routes
  resources :passwords, param: :token

  # OAuth routes
  get "/auth/:provider/callback" => "sessions/omni_auths#create", as: :omniauth_callback
  get "/auth/failure" => "sessions/omni_auths#failure", as: :omniauth_failure

  # Legacy routes for compatibility
  resource :session
  get "/login", to: "sessions#new"
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  get "/pricing", to: "pages#pricing"
  get "/dashboard", to: "pages#dashboard"

  # Settings routes
  get "/settings", to: "settings#show", as: :settings
  patch "/settings/profile", to: "settings#update_profile", as: :update_profile_settings
  patch "/settings/password", to: "settings#update_password", as: :update_password_settings
  delete "/settings/account", to: "settings#destroy_account", as: :destroy_account_settings

  # Organization routes
  resources :organizations, only: [ :index, :new, :create, :show, :edit, :update ] do
    member do
      post :switch
    end

    # Organization members (nested under organizations)
    resources :members, controller: "organization_members", only: [ :index, :destroy, :update ]

    # Organization invitations (nested under organizations)
    resources :invitations, controller: "organization_invitations", only: [ :index, :new, :create, :destroy ]
  end

  # Invitation acceptance (not nested, uses token)
  get "/invitations/:token/accept", to: "organization_invitations#accept", as: :accept_organization_invitation

  # Pay routes are automatically mounted by the gem

  # Subscription routes
  resources :subscriptions, only: [ :create ] do
    collection do
      get :success
      get :cancel
      delete :cancel_subscription
    end
  end

  # Connected account onboarding routes
  resource :connected_account, only: [ :new, :create ] do
    collection do
      get :return
      get :refresh
      get :dashboard
      post :sync
    end
  end

  # Platform charges (for businesses)
  resources :charges, controller: "platform_charges", only: [ :new, :create, :index, :show ]

  # Invoicing routes
  resources :products, controller: "merchant_products" do
    member do
      patch :archive
      patch :unarchive
    end
  end

  resources :customers, controller: "merchant_customers"

  resources :invoices, controller: "merchant_invoices" do
    member do
      post :send_invoice
      post :mark_paid
      post :void
    end
  end

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  root "pages#home"
end
