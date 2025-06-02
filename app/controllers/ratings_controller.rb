class RatingsController < ApplicationController
  skip_before_action :authenticate_user!, only: [:show]

  def show
    rating = Rating.find_by(user: current_user, igdb_game_id: params[:igdb_game_id])
    if rating
      render json: { rating: rating.rating }
    else
      render json: { rating: nil }
    end
  end

  def create
    @rating = Rating.find_or_initialize_by(user: current_user, igdb_game_id: rating_params[:igdb_game_id])
    @rating.rating = rating_params[:rating]
    if @rating.save
      render json: @rating
    else
      render json: { error: @rating.errors.full_messages }, status: :unprocessable_entity
    end
  end

  private

  def rating_params
    params.permit(:igdb_game_id, :rating)
  end
end
