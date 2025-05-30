class Api::GameLikesController < ApplicationController
  before_action :authenticate_user!

  def create
    current_user.game_likes.create!(igdb_game_id: params[:igdb_game_id])
    render json: { success: true }
  end

  def destroy_by_igdb
    like = current_user.game_likes.find_by(igdb_game_id: params[:igdb_game_id])
    if like
      like.destroy
      render json: { success: true }
    else
      render json: { error: "Like not found" }, status: :not_found
    end
  end

end
