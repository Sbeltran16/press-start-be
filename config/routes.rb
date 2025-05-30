Rails.application.routes.draw do

  #Auth/Login Routes
  devise_for :users, path: '', path_names: {
    sign_in: 'login',
    sign_out: 'logout',
    registration: 'signup'
  },
  controllers: {
    sessions: 'users/sessions',
    registrations: 'users/registrations'
  }

  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Current User
  get "/me", to: "users#me"

  #User routes


  # Defines the root path route ("/")
  # root "posts#index"

  #API routes
  get '/api/top_games', to: 'games#top'
  get '/api/games', to: 'games#show_by_name'

  # New route for searching games
  get '/api/games/search', to: 'games#search_by_name'

  # Rewiews Routes
  resources :reviews do
  resources :review_comments, only: [:create, :destroy]
  post 'like', to: 'review_likes#create'
  delete 'unlike', to: 'review_likes#destroy'
  end

  # Ratings Routes
  post '/ratings', to: 'ratings#create'
  get '/ratings/:igdb_game_id', to: 'ratings#show'

end
