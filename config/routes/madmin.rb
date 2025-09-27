# Below are the routes for madmin
namespace :madmin do
  namespace :pay do
    namespace :lemon_squeezy do
      resources :payment_methods
    end
  end
  namespace :pay do
    namespace :lemon_squeezy do
      resources :subscriptions
    end
  end
  namespace :pay do
    namespace :paddle_billing do
      resources :charges
    end
  end
  namespace :pay do
    namespace :fake_processor do
      resources :payment_methods
    end
  end
  namespace :pay do
    namespace :fake_processor do
      resources :subscriptions
    end
  end
  namespace :pay do
    namespace :lemon_squeezy do
      resources :charges
    end
  end
  namespace :pay do
    namespace :lemon_squeezy do
      resources :customers
    end
  end
  namespace :pay do
    namespace :braintree do
      resources :subscriptions
    end
  end
  namespace :pay do
    namespace :fake_processor do
      resources :charges
    end
  end
  namespace :pay do
    namespace :fake_processor do
      resources :customers
    end
  end
  namespace :pay do
    namespace :fake_processor do
      resources :merchants
    end
  end
  namespace :pay do
    namespace :braintree do
      resources :charges
    end
  end
  namespace :pay do
    namespace :braintree do
      resources :customers
    end
  end
  namespace :pay do
    namespace :braintree do
      resources :payment_methods
    end
  end
  namespace :pay do
    resources :payment_methods
  end
  namespace :pay do
    resources :subscriptions
  end
  namespace :pay do
    resources :webhooks
  end
  namespace :pay do
    resources :customers
  end
  namespace :pay do
    resources :merchants
  end
  resources :omni_auth_identities
  resources :sessions
  resources :users
  namespace :pay do
    namespace :paddle_billing do
      resources :customers
    end
  end
  namespace :pay do
    namespace :paddle_billing do
      resources :payment_methods
    end
  end
  namespace :pay do
    namespace :paddle_billing do
      resources :subscriptions
    end
  end
  namespace :pay do
    namespace :paddle_classic do
      resources :charges
    end
  end
  namespace :pay do
    namespace :paddle_classic do
      resources :customers
    end
  end
  namespace :pay do
    namespace :paddle_classic do
      resources :payment_methods
    end
  end
  namespace :pay do
    namespace :paddle_classic do
      resources :subscriptions
    end
  end
  namespace :pay do
    namespace :stripe do
      resources :charges
    end
  end
  namespace :pay do
    namespace :stripe do
      resources :customers
    end
  end
  namespace :pay do
    resources :charges
  end
  namespace :pay do
    namespace :stripe do
      resources :merchants
    end
  end
  namespace :pay do
    namespace :stripe do
      resources :payment_methods
    end
  end
  namespace :pay do
    namespace :stripe do
      resources :subscriptions
    end
  end
  root to: "dashboard#show"
end
