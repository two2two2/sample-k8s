Rails.application.routes.draw do
  root to: "posts#index"
  get ".well-known/acme-challenge/:id" => "home#letsencrypt"
  resources :posts
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
end
