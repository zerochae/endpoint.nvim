Rails.application.routes.draw do
  resources :users do
    collection do
      post :login
    end
  end
  
  resources :posts do
    member do
      post :publish
    end
  end
end