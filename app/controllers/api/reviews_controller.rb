module Api
  class ReviewsController < ApplicationController
    before_action :authenticate_user!, only: [:create, :update, :destroy]
    before_action :set_review, only: [:show, :update, :destroy]
    before_action :authorize_review_owner, only: [:update, :destroy]

    # GET /api/users/:id/reviews
    def user_reviews
      user = User.find(params[:id])
      reviews = user.reviews
                    .includes(:review_likes)
                    .order(created_at: :desc) # Sort newest first

      render json: reviews.map { |review|
        serialize_review(review)
      }, status: :ok
    end

    # GET /api/reviews
    def index
      reviews = Review.all
                      .includes(:review_likes)
                      .order(created_at: :desc)

      render json: reviews.map { |review|
        serialize_review(review)
      }, status: :ok
    end

    # GET /api/reviews/:id
    def show
      render json: serialize_review(@review), status: :ok
    end

    # POST /api/reviews
    def create
      review = current_user.reviews.build(review_params)
      if review.save
        render json: serialize_review(review), status: :created
      else
        render json: { errors: review.errors.full_messages }, status: :unprocessable_entity
      end
    end

    # PATCH/PUT /api/reviews/:id
    def update
      if @review.update(review_params)
        render json: serialize_review(@review), status: :ok
      else
        render json: { errors: @review.errors.full_messages }, status: :unprocessable_entity
      end
    end

    # DELETE /api/reviews/:id
    def destroy
      @review.destroy
      render json: { message: 'Review deleted' }, status: :ok
    end

    private

    def set_review
      @review = Review.find(params[:id])
    end

    def authorize_review_owner
      unless @review.user_id == current_user.id
        render json: { errors: ['Not authorized'] }, status: :forbidden
      end
    end

    def review_params
      params.require(:review).permit(:comment, :rating, :igdb_game_id)
    end

    # Centralized serializer for plain JSON
    def serialize_review(review)
      {
        id: review.id,
        comment: review.comment,
        rating: review.rating,
        igdb_game_id: review.igdb_game_id,
        likes_count: review.review_likes.count,
        liked_by_current_user: current_user ? review.review_likes.exists?(user_id: current_user.id) : false,
        created_at: review.created_at,
        updated_at: review.updated_at,
        user_id: review.user_id
      }
    end
  end
end
