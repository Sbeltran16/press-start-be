module Api
  class ReviewsController < ApplicationController
    before_action :authenticate_user!, only: [:create]

    def user_reviews
      user = User.find(params[:id])
      reviews = user.reviews  # no includes(:game)
      render json: reviews, each_serializer: ReviewSerializer
    end

    def index
      reviews = Review.all  # no includes(:game)
      render json: reviews, each_serializer: ReviewSerializer
    end

    def create
      review = current_user.reviews.build(review_params)
      if review.save
        render json: review, status: :created, serializer: ReviewSerializer
      else
        render json: { errors: review.errors.full_messages }, status: :unprocessable_entity
      end
    end

    private

    def review_params
      params.require(:review).permit(:comment, :rating, :igdb_game_id)
    end
  end
end
