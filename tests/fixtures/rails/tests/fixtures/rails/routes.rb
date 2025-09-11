Rails.application.routes.draw do
  post '/users/login', to: 'users#login'
  get '/users/new', to: 'users#new'
  resources :users do
    resources :projects
  end
  match 'users', to: 'users#index', via: [:get, :options]
end
