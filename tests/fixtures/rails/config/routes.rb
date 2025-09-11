Rails.application.routes.draw do
  root 'home#index'

  resources :users do
    member do
      get :profile
      patch :update_status
    end

    collection do
      get :search
    end
  end

  resources :posts do
    resources :comments, except: [:show]

    member do
      post :like
      delete :unlike
      post :share
    end
  end

  resources :products do
    resources :reviews

    collection do
      get :featured
      get :on_sale
    end
  end

  namespace :admin do
    resources :users, :products, :orders
    root 'dashboard#index'
  end

  namespace :api do
    namespace :v1 do
      resources :users, only: %i[index show create update]
      resources :products, only: %i[index show]
    end
  end
end

