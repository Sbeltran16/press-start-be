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

  # Defines the root path route ("/")
  # root "posts#index"

  #Activities Routes
  get "/api/activity_feed", to: "activities#feed"


  #API Routes
  namespace :api do
    #Game Interaction Routes
    post 'game_likes', to: 'game_likes#create'
    delete 'game_likes', to: 'game_likes#destroy_by_igdb'

    post 'game_plays', to: 'game_plays#create'
    delete 'game_plays', to: 'game_plays#destroy_by_igdb'

    #Platform Logos
    get "platform_logos", to: "platform_logos#index"

    #Game Routes
    get 'top_games', to: 'games#top'
    get 'games', to: 'games#show_by_name'
    get 'games/search', to: 'games#search_by_name'
    get 'popular', to: 'games#popular'
    get 'user_game_status', to: 'games#user_game_status'
    get 'games/:id', to: 'games#show_by_id'
    get 'igdb/external_games/:id', to: 'external_games#show'

    #Favorite Games
    get 'favorite_games', to: 'favorite_games#index'
    patch 'favorite_games', to: 'favorite_games#update'

    #Backlog Games
    get 'backlog_games', to: 'backlog_games#index'
    post 'backlog_games', to: 'backlog_games#create'
    delete 'backlog_games/:id', to: 'backlog_games#destroy'

    #User Review Routes
    resources :users, only: [] do
      get 'reviews', to: 'reviews#user_reviews', on: :member
    end

    resources :reviews, only: [:index, :create, :show, :update, :destroy] do
      resources :review_comments, only: [:index, :create, :destroy], path: 'comments'
      post 'like', to: 'review_likes#create'
      delete 'unlike', to: 'review_likes#destroy'
    end
  end

  resources :users, only: [] do
    member do
      get 'followers', to: 'follows#followers'
      get 'following', to: 'follows#following'
    end
  end

  #Follows Routes
  resources :follows, only: [:create, :destroy]
  get "follows/:id/status", to: "follows#status"

  # Ratings Routes
  post '/ratings', to: 'ratings#create'
  get '/ratings/:igdb_game_id', to: 'ratings#show'

  #User routes
  get "/me", to: "users#me"
  get '/users/:username', to: 'users#show'
  patch "/users/update_picture", to: "users#update_picture"

end
