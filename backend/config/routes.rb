Rails.application.routes.draw do
  namespace :api do
    namespace :v1 do
      post "signup", to: "auth#signup"
      post "login",  to: "auth#login"
      post "ekasa/find", to: "ekasa#find"
      post "bysquare/decode", to: "bysquare#decode"
      get  "me",     to: "users#me"
      patch "me",    to: "users#update"
      resources :invoices do
        member do
          get "history"
          patch "cancel"
        end
      end
      resources :companies, only: [:index, :show, :create, :update]
      resources :receipts
    end
  end
end