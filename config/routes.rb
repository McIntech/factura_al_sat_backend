# config/routes.rb
Rails.application.routes.draw do
  # Health check endpoint
  get 'up' => 'rails/health#show', as: :rails_health_check

  # Devise routes for User model with custom paths and controllers
  devise_for :users,
             defaults: { format: :json },
             path: 'api/v1/auth',
             controllers: {
               sessions: 'api/v1/auth/sessions',
               registrations: 'api/v1/auth/registrations',
               passwords: 'devise/passwords'
             },
             path_names: {
               sign_in: 'login',
               sign_out: 'logout',
               registration: 'signup',
               sign_up: 'signup'
             }

  # API namespace
  namespace :api do
    namespace :v1 do
      resources :users, only: %i[index create update destroy show]
      resources :invoices, only: %i[index create update destroy show] do
        collection do
          get 'rfc/:rfc', to: 'invoices#find_by_rfc'
          get 'code/:code', to: 'invoices#show_by_code'
          post 'send_email', to: 'invoice_mailer#send_email'
        end
      end
      get '/auth/validate_token', to: 'auth#validate_token'
      # Proxy para imágenes con CORS
      get '/images/proxy', to: 'images#proxy'
      # Test email route
      get '/test_email', to: 'test_mailer#test_email'
    end
    # API v1 (sin namespacing específico)
    resources :personas
  end
end
