Rails.application.routes.draw do
  # Devise authentication
  devise_for :users

  # Root
  root to: "movies#index"

  # This route will return just the “results” partial
  get "/movies/live_search", to: "movies#live_search", as: :live_search_movies
  # Movies
  resources :movies, only: [:index, :show]

  # Genres
  resources :genres, only: [:index]

  # Favorites (watchlist-style)
  resources :favorites, only: [:index, :create, :destroy]

  # Cast and characters (optional unless you build cast browsing UI)
  resources :casts, only: [:index, :show]
  resources :characters, only: [:create, :destroy]

  # AI Recommendations (mood-based)
  get 'recommendations/mood', to: 'recommendations#mood', as: :mood_recommendations
  post 'recommendations/generate', to: 'recommendations#generate', as: :generate_recommendations

  # Static or dashboard pages
  get 'dashboard', to: 'pages#dashboard'

  # Health check for uptime monitor
  get "up" => "rails/health#show", as: :rails_health_check

  # Genres Category Index
  resources :genres, only: [:index]
end
