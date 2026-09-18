Rails.application.routes.draw do
  # MCP endpoint for Claude Desktop integration
  post "mcp", to: "mcp/sessions#create"

  # REST API
  namespace :api do
    namespace :v1 do
      resources :posts, only: [ :index, :show, :create, :update, :destroy ], param: :slug do
        member do
          post :publish
          post :schedule
          post :unpublish
        end
      end
      resources :categories, only: [ :index ]
      resources :tags, only: [ :index, :create ]
      resource :site, only: [ :show ], controller: "site"
      resources :assets, only: [ :create ]
    end
  end

  # Webhooks (public, no auth)
  post "webhooks/sendgrid", to: "webhooks/sendgrid#create"
  post "webhooks/stripe", to: "webhooks/stripe#create"

  # ActivityPub / fediverse federation (404 unless enabled in settings)
  get ".well-known/webfinger", to: "activity_pub/webfinger#show", as: :webfinger
  namespace :activity_pub, path: "activitypub" do
    resource :actor, only: [ :show ]
    resource :inbox, only: [ :create ]
    get "outbox", to: "collections#outbox"
    get "followers", to: "collections#followers"
    get "following", to: "collections#following"
  end
  # Fediverse servers dereference a post's URL with an ActivityPub Accept header.
  get "posts/:slug", to: "activity_pub/objects#show", constraints: ->(request) { ActivityPub::Negotiation.matches?(request) }

  # Public
  root "posts#index"
  resources :posts, only: [ :index, :show ], param: :slug do
    resource :love, only: [ :create, :destroy ]
    resources :comments, only: [ :create, :update, :destroy ]
  end
  resources :authors, only: [ :index, :show ], param: :handle
  resources :categories, only: [ :show ], param: :slug
  resources :tags, only: [ :show ], param: :slug
  resources :subscriptions, only: [ :create ]
  resource :subscriber_session, only: [ :show, :destroy ]
  resource :handle, only: [ :update ]
  resource :handle_availability, only: [ :show ]
  resource :unsubscribe, only: [ :show, :create ]
  resource :email_preferences, only: [ :show, :update ], path: "email-preferences"
  resource :comment_notification, only: [ :destroy ]
  resource :reading_list, only: [ :show ], path: "reading-list", controller: "reading_list" do
    resources :posts, only: [ :index ], controller: "reading_list_posts"
    resources :items, only: [ :create, :destroy ], controller: "reading_list_items", param: :post_id
    resource :import, only: [ :create ], controller: "reading_list_imports"
  end
  resources :memberships, only: [ :index ] do
    collection do
      post :checkout
      get :success
      get :portal
    end
  end
  get "feed" => "feeds#index", defaults: { format: :xml }
  get "sitemap" => "sitemaps#index", defaults: { format: :xml }
  get "robots" => "robots#index", defaults: { format: :text }, as: :robots

  # Admin
  namespace :admin do
    root "dashboard#show"
    resource :setup, only: [ :new, :create ], controller: "setup"
    resource :session, only: [ :new, :create, :destroy ]

    # Passkey authentication (unauthenticated)
    namespace :passkey_authentication do
      post :options
      post :verify
    end

    # Passkey management (authenticated)
    resources :passkeys, only: [ :index, :create, :destroy ] do
      collection do
        post :registration_options
      end
    end
    resources :posts do
      member do
        get :preview
      end
      resources :post_versions, only: [ :index, :show, :create ] do
        member do
          post :restore
        end
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
    resources :subscriber_labels
    resources :mailing_lists, except: [ :show ]
    resources :segments do
      member { get :count }
    end
    resources :subscribers, only: [ :index, :show ] do
      resources :subscriber_labelings, only: [ :create, :destroy ]
      post "memberships/comp", to: "memberships#comp", as: :comp_membership
    end
    resource :growth, only: [ :show ], controller: "growth"
    resource :traffic, only: [ :show ], controller: "traffic"
    resource :profile, only: [ :edit, :update ]
    resource :settings, only: [ :edit, :update ]
    resource :newsletter_settings, only: [ :edit, :update ]
    resources :pages
    resources :navigation_items, path: "navigation", except: [ :show, :new ] do
      member { patch :move }
      collection { patch :reorder }
    end
    resources :membership_tiers, except: [ :show ]
    resources :memberships, only: [ :index, :show, :destroy ]
    resource :revenue, only: [ :show ], controller: "revenue"
    resources :api_tokens, only: [ :index, :create, :destroy ]
    resources :webhooks do
      member do
        post :test
        post :regenerate_secret
      end
      resources :webhook_deliveries, only: [ :index ]
    end
    resources :exports, only: [ :index, :create, :destroy ]
    get "exports/:id/download", to: "export_downloads#show", as: :export_download
  end

  # Health check
  get "up" => "rails/health#show", as: :rails_health_check

  # Static pages — catch-all must be last
  get ":slug" => "pages#show", as: :page, constraints: { slug: /[a-z0-9]+(?:-[a-z0-9]+)*/ }
end
