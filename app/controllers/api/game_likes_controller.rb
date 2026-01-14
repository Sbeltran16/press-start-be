class Api::GameLikesController < ApplicationController
  before_action :authenticate_user!

  def create
    igdb_game_id = params[:igdb_game_id]
    return render json: { error: "Missing igdb_game_id" }, status: :bad_request if igdb_game_id.blank?

    # Check if already exists to avoid duplicate key errors
    existing_like = current_user.game_likes.find_by(igdb_game_id: igdb_game_id)
    if existing_like
      render json: { success: true, message: "Already liked" }
      return
    end

    like = current_user.game_likes.build(igdb_game_id: igdb_game_id)
    if like.save
      render json: { success: true }
    else
      render json: { error: like.errors.full_messages.join(", ") }, status: :unprocessable_entity
    end
  rescue ActiveRecord::RecordNotUnique
    # Handle race condition where like was created between check and save
    render json: { success: true, message: "Already liked" }
  end

  def destroy_by_igdb
    igdb_game_id = params[:igdb_game_id]
    return render json: { error: "Missing igdb_game_id" }, status: :bad_request if igdb_game_id.blank?

    like = current_user.game_likes.find_by(igdb_game_id: igdb_game_id)
    if like
      like.destroy
      render json: { success: true }
    else
      render json: { error: "Like not found" }, status: :not_found
    end
  end

end
