class Api::GamePlaysController < ApplicationController
  before_action :authenticate_user!

  def create
    current_user.game_plays.create!(igdb_game_id: params[:igdb_game_id])
    render json: { success: true }
  end

  def destroy_by_igdb
    played = current_user.game_plays.find_by(igdb_game_id: params[:igdb_game_id])
    if played
      played.destroy
      render json: { success: true }
    else
      render json: { error: "Like not found" }, status: :not_found
    end
  end
end
