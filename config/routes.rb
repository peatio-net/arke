Rails.application.routes.draw do
  resources :strategies
  resources :balances
  resources :accounts
  resources :markets
  resources :exchanges
  get 'users/me', to: 'users#me'
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
end
