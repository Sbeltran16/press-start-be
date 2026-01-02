module Api
  class ReviewsController < ApplicationController
    before_action :authenticate_user!, only: [:create, :update, :destroy]

    # GET /api/users/:id/reviews
    def user_reviews
      user = User.find(params[:id])
      reviews = user.reviews
                    .includes(:review_likes, :review_comments, :user)
                    .order(created_at: :desc) # Sort newest first

      render json: reviews.map { |review|
        serialize_review(review)
      }, status: :ok
    end

    # GET /api/reviews
    def index
      reviews = Review.all
                      .includes(:review_likes, :review_comments, :user)
                      .order(created_at: :desc)

      render json: reviews.map { |review|
        serialize_review(review)
      }, status: :ok
    end

    # GET /api/reviews/popular
    def popular
      # Get reviews from the past week, ordered by likes count
      # If no reviews from past week, get all reviews
      week_ago = 1.week.ago
      
      # Get all reviews from the past week with their like counts
      reviews_with_likes = Review.where("created_at >= ?", week_ago)
                                 .includes(:review_likes, :review_comments, :user)
                                 .map { |review|
                                   [review, review.review_likes.size]
                                 }
                                 .sort_by { |_, likes_count| -likes_count }
                                 .first(4)
                                 .map(&:first)

      # If no reviews from past week, get all reviews ordered by likes
      if reviews_with_likes.empty?
        reviews_with_likes = Review.all
                                   .includes(:review_likes, :review_comments, :user)
                                   .map { |review|
                                     [review, review.review_likes.size]
                                   }
                                   .sort_by { |_, likes_count| -likes_count }
                                   .first(4)
                                   .map(&:first)
      end

      # Log for debugging
      Rails.logger.info "Popular reviews count: #{reviews_with_likes.size}"

      render json: reviews_with_likes.map { |review|
        serialize_review(review)
      }, status: :ok
    end

    # GET /api/reviews/:id
    def show
      review = Review.includes(:review_likes, :review_comments, :user).find(params[:id])
      render json: serialize_review(review), status: :ok
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

    # PATCH /api/reviews/:id
    def update
      review = Review.find(params[:id])
      
      # Only allow the review owner to update
      if review.user_id != current_user.id
        render json: { errors: ["Not authorized"] }, status: :forbidden
        return
      end

      if review.update(review_params)
        render json: serialize_review(review), status: :ok
      else
        render json: { errors: review.errors.full_messages }, status: :unprocessable_entity
      end
    end

    # DELETE /api/reviews/:id
    def destroy
      review = Review.find(params[:id])
      
      # Only allow the review owner to delete
      if review.user_id != current_user.id
        render json: { errors: ["Not authorized"] }, status: :forbidden
        return
      end

      review.destroy
      render json: { message: "Review deleted" }, status: :ok
    end

    private

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
        likes_count: review.review_likes.size,
        liked_by_current_user: current_user ? review.review_likes.exists?(user_id: current_user.id) : false,
        comments_count: review.review_comments.size,
        created_at: review.created_at,
        updated_at: review.updated_at,
        user_id: review.user_id,
        user: {
          id: review.user.id,
          username: review.user.username,
          profile_picture_url: review.user.profile_picture_url
        }
      }
    end
  end
end
