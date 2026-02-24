Rails.application.routes.draw do
  # MCP endpoint for Claude Desktop integration
  post "mcp", to: "mcp/sessions#create"

  # Webhooks (public, no auth)
  post "webhooks/sendgrid", to: "webhooks/sendgrid#create"

  # Public
  root "posts#index"
  resources :posts, only: [ :index, :show ], param: :slug do
    resource :love, only: [ :create, :destroy ]
    resources :comments, only: [ :create ]
  end
  resources :authors, only: [ :index, :show ], param: :handle
  resources :categories, only: [ :show ], param: :slug
  resources :tags, only: [ :show ], param: :slug
  resources :subscriptions, only: [ :create ]
  resource :subscriber_session, only: [ :show, :destroy ]
  resource :handle, only: [ :update ]
  resource :handle_availability, only: [ :show ]
  resource :unsubscribe, only: [ :show, :create ]
  get "feed" => "feeds#index", defaults: { format: :xml }
  get "sitemap" => "sitemaps#index", defaults: { format: :xml }
  get "robots" => "robots#index", defaults: { format: :text }, as: :robots

  # Admin
  namespace :admin do
    root "dashboard#show"
    resource :setup, only: [ :new, :create ], controller: "setup"
    resource :session, only: [ :new, :create, :destroy ]
    resources :posts do
      member do
        get :preview
      end
      resource :dashboard, only: [ :show ], controller: "post_dashboard"
      namespace :ai do
        resource :conversation, only: [ :show, :create ]
        resources :messages, only: [ :create ]
        resource :featured_image, only: [ :create ], controller: "featured_images" do
          post :suggest_prompt, on: :collection
        end
      end
    end
    resources :x_posts, only: [ :create ]
    resources :youtube_videos, only: [ :create ]
    resources :tags, only: [ :create ]
    resources :categories
    resources :comments, only: [ :index, :update, :destroy ]
    resources :newsletters do
      member do
        post :send_newsletter
        post :schedule
        get :preview
      end
    end
    resources :subscribers, only: [ :index, :show ]
    resource :growth, only: [ :show ], controller: "growth"
    resource :profile, only: [ :edit, :update ]
    resource :settings, only: [ :edit, :update ]
    resource :newsletter_settings, only: [ :edit, :update ]
    resources :pages
    resources :api_tokens, only: [ :index, :create, :destroy ]
  end

  # Health check
  get "up" => "rails/health#show", as: :rails_health_check

  # Static pages — catch-all must be last
  get ":slug" => "pages#show", as: :page, constraints: { slug: /[a-z0-9]+(?:-[a-z0-9]+)*/ }
end
