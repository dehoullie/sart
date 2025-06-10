Rails.application.routes.draw do
  # Devise authentication
  devise_for :users

  # Root
  root to: "movies#index"

  # This route will return just the “results” partial
  get "/movies/live_search", to: "movies#live_search", as: :live_search_movies

  # Movies
  resources :movies, only: [:index, :show]

  # Directors
  # This is the ONLY `resources :casts` line that should define the 'show' action
  # if you intend /casts/:id to go to DirectorsController.
  # resources :casts, only: [:show], controller: 'directors' # Keep this one!
  resources :directors, only: [:index, :show]

  # Genres
  resources :genres, only: [:index] # Keep only one of these

  # Favorites (watchlist-style)
  resources :favorites, only: [:index, :create, :destroy]

  # Cast and characters (optional unless you build cast Browse UI)
  # REMOVE THE FOLLOWING LINE if you want /casts/:id to always go to the director's page.
  # If you *do* want a general 'casts#index' to list all cast members,
  # you'd need to define it specifically (e.g., 'get "casts", to: "casts#index"').
  # For the director profile feature, this line is causing the conflict.
  resources :casts, only: [:index, :show]

  # Characters (These are fine)
  resources :characters, only: [:create, :destroy]

  # AI Recommendations (mood-based)
  get 'recommendations/mood', to: 'recommendations#mood', as: :mood_recommendations
  post 'recommendations/generate', to: 'recommendations#generate', as: :generate_recommendations

  # Static or dashboard pages
  get 'dashboard', to: 'pages#dashboard'

  # Health check for uptime monitor
  get "up" => "rails/health#show", as: :rails_health_check

  # Set country
  post "/set_country", to: "countries#set"

  resources :questions, only: [:index, :create]
  # Profile
  resource :profile, only: [:show, :edit, :update]

  # Mission control to see jobs
  mount MissionControl::Jobs::Engine, at: "/jobs"

end
