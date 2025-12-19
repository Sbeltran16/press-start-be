module Api
  class ReviewLikesController < ApplicationController
    before_action :authenticate_user!

    # POST /api/reviews/:review_id/like
    def create
      review = Review.find(params[:review_id])
      like = review.review_likes.find_or_initialize_by(user: current_user)

      if like.persisted? || like.save
        render json: { liked: true, likes_count: review.review_likes.count }, status: :ok
      else
        render json: { errors: like.errors.full_messages }, status: :unprocessable_entity
      end
    end

    # DELETE /api/reviews/:review_id/unlike
    def destroy
      review = Review.find(params[:review_id])
      like = review.review_likes.find_by(user: current_user)
      like&.destroy

      render json: { liked: false, likes_count: review.review_likes.count }, status: :ok
    end
  end
end
