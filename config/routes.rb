Rails.application.routes.draw do
  # Public
  root "posts#index"
  resources :posts, only: [ :index, :show ], param: :slug do
    resource :love, only: [ :create, :destroy ]
    resources :comments, only: [ :create ]
  end
  resources :categories, only: [ :show ], param: :slug
  resources :tags, only: [ :show ], param: :slug
  resources :subscriptions, only: [ :create ]
  resource :subscriber_session, only: [ :show, :destroy ]
  resource :handle, only: [ :update ]
  resource :handle_availability, only: [ :show ]
  get "feed" => "feeds#index", defaults: { format: :xml }
  get "sitemap" => "sitemaps#index", defaults: { format: :xml }
  get "about" => "pages#about"

  # Admin
  namespace :admin do
    root "dashboard#show"
    resource :setup, only: [ :new, :create ], controller: "setup"
    resource :session, only: [ :new, :create, :destroy ]
    resources :posts do
      resource :dashboard, only: [ :show ], controller: "post_dashboard"
    end
    resources :categories
    resources :comments, only: [ :index, :update, :destroy ]
    resources :subscribers, only: [ :index, :show ]
    resource :settings, only: [ :edit, :update ]
  end

  # Health check
  get "up" => "rails/health#show", as: :rails_health_check
end
