Rails.application.routes.draw do
  # Auth routes
  post '/users/login', to: 'users#login'
  post '/users/logout', to: 'users#logout'
  get '/users/new', to: 'users#new' # This route is for testing purpose
  
  # User resources with nested resources
  resources :users, shallow: true do
    resources :projects
    resource :avatar, only: [:create, :update, :destroy], controller: 'users/avatar'
    member do
      patch :activate
      patch :deactivate
      get :profile
    end
    collection do
      get :search
      get :export
    end
  end
  
  # Additional user routes with match
  match 'users', to: 'users#index', via: [:get, :options]
  match 'users/bulk', to: 'users#bulk_create', via: [:post]
  
  # API namespace
  namespace :api do
    namespace :v1 do
      resources :articles, except: [:new, :edit] do
        member do
          post :publish
          post :unpublish
          get :stats
        end
        resources :comments, only: [:index, :create, :destroy]
      end
      
      resources :categories, only: [:index, :show]
      resources :tags, only: [:index, :show, :create]
      
      # Custom API routes
      get 'search', to: 'search#index'
      post 'upload', to: 'upload#create'
      get 'health', to: 'health#check'
    end
    
    namespace :v2 do
      resources :articles, only: [:index, :show] do
        get :related, on: :member
      end
    end
  end
  
  # Admin namespace
  namespace :admin do
    get 'dashboard', to: 'dashboard#index'
    get 'dashboard/stats', to: 'dashboard#stats'
    get 'dashboard/health', to: 'dashboard#health'
    post 'dashboard/maintenance', to: 'dashboard#maintenance'
    
    resources :users, only: [:index, :show, :edit, :update, :destroy] do
      patch :ban, on: :member
      patch :unban, on: :member
    end
    
    resources :articles, except: [:new, :create] do
      patch :feature, on: :member
      patch :unfeature, on: :member
    end
  end
  
  # Webhook routes
  scope :webhooks do
    post 'github', to: 'webhooks#github'
    post 'stripe', to: 'webhooks#stripe'
    post 'mailgun', to: 'webhooks#mailgun'
  end
  
  # Catch-all route for SPA
  get '*path', to: 'application#spa', constraints: lambda { |req|
    !req.xhr? && req.format.html?
  }
  
  # Mount engines
  mount OasRails::Engine => '/docs'
  
  # Health check
  get '/health', to: 'health#check'
  
  # Root route
  root 'home#index'
end