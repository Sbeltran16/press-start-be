class Api::FavoriteGamesController < ApplicationController
  before_action :authenticate_user!


  def index
    render json: current_user.favorite_games.pluck(:igdb_game_id)
  end

  def update
    igdb_ids = params[:favorite_games] # array of IGDB game IDs
    if igdb_ids.is_a?(Array) && igdb_ids.size <= 4
      # Remove all old favorites
      current_user.favorite_games.destroy_all
  
      # Create new favorites with IGDB IDs
      igdb_ids.each do |igdb_id|
        current_user.favorite_games.create!(igdb_game_id: igdb_id)
      end
  
      render json: { message: "Favorites updated" }, status: :ok
    else
      render json: { error: "Invalid favorite games list" }, status: :unprocessable_entity
    end
  end
  
end
