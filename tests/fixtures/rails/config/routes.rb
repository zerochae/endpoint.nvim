Rails.application.routes.draw do
  root 'home#index'

  # Authentication routes
  post '/login', to: 'sessions#create'
  delete '/logout', to: 'sessions#destroy'
  get '/profile', to: 'users#profile'

  # User management
  resources :users, except: [:new, :edit] do
    member do
      patch :activate
      patch :deactivate
      get :posts
    end
    
    collection do
      post :login
      get :search
    end
  end

  # Post management with nested comments
  resources :posts do
    resources :comments, except: [:new, :edit, :show]
    
    member do
      post :publish
      post :unpublish
      post :like
      delete :like, action: :unlike
    end
    
    collection do
      get :published
      get :drafts
      get :popular
    end
  end

  # API namespace with versioning
  namespace :api do
    namespace :v1 do
      resources :articles, except: [:new, :edit] do
        member do
          post :like
          get :related
        end
        
        collection do
          get :featured
          get :trending
        end
        
        resources :comments, only: [:index, :create, :destroy]
      end
      
      resources :categories, only: [:index, :show]
      resources :tags, only: [:index, :show, :create]
      
      # Custom API endpoints
      get '/health', to: 'health#check'
      post '/upload', to: 'uploads#create'
      get '/search', to: 'search#index'
    end
    
    namespace :v2 do
      resources :articles, only: [:index, :show] do
        get :metadata, on: :member
      end
    end
  end

  # Admin panel
  namespace :admin do
    get '/dashboard', to: 'dashboard#index'
    get '/dashboard/analytics', to: 'dashboard#analytics'
    post '/dashboard/maintenance', to: 'dashboard#maintenance'
    get '/dashboard/health', to: 'dashboard#health'
    post '/dashboard/backup', to: 'dashboard#backup'
    
    resources :users, except: [:new, :create, :edit] do
      patch :ban, on: :member
      patch :unban, on: :member
    end
    
    resources :posts, except: [:new, :create, :edit] do
      patch :feature, on: :member
      patch :moderate, on: :member
    end
  end

  # Webhooks
  scope :webhooks do
    post '/github', to: 'webhooks#github'
    post '/stripe', to: 'webhooks#stripe'
    post '/mailgun', to: 'webhooks#mailgun'
  end

  # File uploads and downloads
  resources :uploads, only: [:create, :show, :destroy]
  get '/downloads/:id', to: 'downloads#show', as: :download

  # Static pages
  get '/about', to: 'pages#about'
  get '/contact', to: 'pages#contact'
  post '/contact', to: 'pages#create_contact'

  # Catch-all for SPA routing (should be last)
  get '*path', to: 'application#render_spa', constraints: lambda { |request|
    !request.xhr? && request.format.html?
  }
end