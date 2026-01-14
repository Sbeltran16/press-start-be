class Api::GamePlaysController < ApplicationController
  before_action :authenticate_user!

  def create
    igdb_game_id = params[:igdb_game_id]
    return render json: { error: "Missing igdb_game_id" }, status: :bad_request if igdb_game_id.blank?

    # Check if already exists to avoid duplicate key errors
    existing_play = current_user.game_plays.find_by(igdb_game_id: igdb_game_id)
    if existing_play
      render json: { success: true, message: "Already marked as played" }
      return
    end

    play = current_user.game_plays.build(igdb_game_id: igdb_game_id)
    if play.save
      render json: { success: true }
    else
      render json: { error: play.errors.full_messages.join(", ") }, status: :unprocessable_entity
    end
  rescue ActiveRecord::RecordNotUnique
    # Handle race condition where play was created between check and save
    render json: { success: true, message: "Already marked as played" }
  end

  def destroy_by_igdb
    igdb_game_id = params[:igdb_game_id]
    return render json: { error: "Missing igdb_game_id" }, status: :bad_request if igdb_game_id.blank?

    played = current_user.game_plays.find_by(igdb_game_id: igdb_game_id)
    if played
      played.destroy
      render json: { success: true }
    else
      render json: { error: "Played status not found" }, status: :not_found
    end
  end
end
