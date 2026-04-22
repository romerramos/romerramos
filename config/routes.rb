Rails.application.routes.draw do
  # Authentication routes (outside locale scope)
  resource :session, only: [ :new, :create, :destroy ]
  get    "login"  => "sessions#new",     as: :login
  post   "login"  => "sessions#create"
  delete "logout" => "sessions#destroy", as: :logout
  resources :passwords, param: :token, only: [ :new, :create, :edit, :update ]

  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  namespace :admin do
    get "/", to: redirect("/admin/posts")
    resources :posts
  end

  scope "/:locale", locale: /en|es/ do
    # Defines the root path route ("/")
    root "home#index"
    resource :about, only: [ :show ], controller: "about"
  end

  # Redirect root to default locale
  get "/", to: redirect("/en")
end
