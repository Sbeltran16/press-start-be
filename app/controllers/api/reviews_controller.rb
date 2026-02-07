module Api
  class ReviewsController < ApplicationController
    before_action :authenticate_user!, only: [:create, :update, :destroy, :from_friends]

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
      # Get time period from params (this_week, this_month, this_year, all_time)
      time_period = params[:period] || 'this_week'
      limit = params[:limit] ? params[:limit].to_i : nil
      
      # Calculate date threshold based on time period
      date_threshold = case time_period
      when 'this_week'
        1.week.ago
      when 'this_month'
        1.month.ago
      when 'this_year'
        1.year.ago
      when 'all_time'
        nil
      else
        1.week.ago # Default to this week
      end
      
      # Build query based on time period
      base_query = Review.includes(:review_likes, :review_comments, :user)
      
      if date_threshold
        base_query = base_query.where("created_at >= ?", date_threshold)
      end
      
      # Get all reviews with their like counts, sorted by likes
      reviews_with_likes = base_query
                           .map { |review|
                             [review, review.review_likes.size]
                           }
                           .sort_by { |_, likes_count| -likes_count }
      
      # Apply limit if specified, otherwise use default of 4 for dashboard
      # Map to get just the reviews, then apply limit
      reviews_with_likes = reviews_with_likes.map(&:first)
      reviews_with_likes = reviews_with_likes.first(limit || 4)

      # Log for debugging
      Rails.logger.info "Popular reviews count: #{reviews_with_likes.size}, period: #{time_period}"

      render json: reviews_with_likes.map { |review|
        serialize_review(review)
      }, status: :ok
    end

    # GET /api/reviews/from_friends
    # Returns newest reviews from users the current user follows (and optionally themself)
    def from_friends
      limit = params[:limit] ? params[:limit].to_i : 4
      limit = 4 if limit <= 0

      following_ids = current_user.following.pluck(:id)

      if following_ids.empty?
        render json: [], status: :ok
        return
      end

      reviews = Review.where(user_id: following_ids)
                      .includes(:review_likes, :review_comments, :user)
                      .order(created_at: :desc)
                      .limit(limit)

      render json: reviews.map { |review| serialize_review(review) }, status: :ok
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
