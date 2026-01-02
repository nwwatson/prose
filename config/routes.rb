Rails.application.routes.draw do
  # Authentication routes
  resources :sessions, only: [ :new, :create ]
  delete "sign_out", to: "sessions#destroy"

  resources :registrations, only: [ :new, :create ], path: "register"

  resources :confirmations, only: [ :new, :create ]
  get "confirm/:token", to: "confirmations#show", as: :confirmation

  # Account management
  resources :accounts

  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Publications management (nested under accounts)
  resources :accounts do
    resources :publications do
      resources :posts, except: [ :index ] do
        member do
          get :preview
          patch :publish
          patch :unpublish
        end
      end
    end
  end

  # Top-level publications for dashboard
  resources :publications, only: [ :index ]

  # Defines the root path route ("/")
  root "accounts#index"
end
