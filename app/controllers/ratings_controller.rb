class RatingsController < ApplicationController
  before_action :authenticate_user!

  def show
    rating = Rating.find_by(user: current_user, igdb_game_id: params[:igdb_game_id])
    if rating
      render json: { rating: rating.rating }
    else
      render json: { rating: nil }
    end
  end

  def create
    Rails.logger.info "Params: #{params.inspect}"
    Rails.logger.info "Current user: #{current_user.inspect}"
  
    @rating = Rating.find_or_initialize_by(user: current_user, igdb_game_id: rating_params[:igdb_game_id])
    @rating.rating = rating_params[:rating]
    if @rating.save
      render json: @rating
    else
      render json: { error: @rating.errors.full_messages }, status: :unprocessable_entity
    end
  rescue => e
    Rails.logger.error "Error in RatingsController#create: #{e.message}"
    render json: { error: e.message }, status: 500
  end
  
  private

  def rating_params
    params.permit(:igdb_game_id, :rating)
  end
end
