module Api
  class ReviewsController < ApplicationController
    before_action :authenticate_user!, only: [:create, :update, :destroy, :from_friends, :upload_cover]

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
      review_params_data = review_params.except(:custom_cover_url, :custom_cover_blob_key)
      review = current_user.reviews.build(review_params_data)
      
      # Handle custom cover - attach the blob if blob_key or URL is provided
      if params[:review][:custom_cover_blob_key].present?
        # Use blob_key directly (more reliable)
        blob = ActiveStorage::Blob.find_by(key: params[:review][:custom_cover_blob_key])
        review.custom_cover.attach(blob) if blob
      elsif params[:review][:custom_cover_url].present?
        # Fallback to URL parsing
        custom_cover_url = params[:review][:custom_cover_url]
        begin
          url_path = URI.parse(custom_cover_url).path
          # Extract blob key from path (format: /rails/active_storage/blobs/:key/:filename)
          if url_path.include?('/rails/active_storage/blobs/')
            blob_key = url_path.split('/rails/active_storage/blobs/').last.split('/').first
            blob = ActiveStorage::Blob.find_by(key: blob_key)
            review.custom_cover.attach(blob) if blob
          end
        rescue => e
          Rails.logger.error("Error attaching custom cover: #{e.message}")
        end
      end
      
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

      review_params_data = review_params.except(:custom_cover_url, :custom_cover_blob_key)
      
      # Handle custom cover changes
      if params[:review][:custom_cover_blob_key].present?
        # User selected a new custom cover (uploaded) - attach the blob
        blob = ActiveStorage::Blob.find_by(key: params[:review][:custom_cover_blob_key])
        if blob
          review.custom_cover.purge if review.custom_cover.attached? # Remove old custom cover
          review.custom_cover.attach(blob)
        end
        # Clear cover_image_id when custom cover is set
        review_params_data[:cover_image_id] = nil if params[:review][:cover_image_id] == ""
      elsif params[:review][:custom_cover_url].present? && params[:review][:custom_cover_blob_key].blank?
        # User selected existing custom cover or provided URL - find blob from URL
        custom_cover_url = params[:review][:custom_cover_url]
        begin
          url_path = URI.parse(custom_cover_url).path
          if url_path.include?('/rails/active_storage/blobs/')
            blob_key = url_path.split('/rails/active_storage/blobs/').last.split('/').first
            blob = ActiveStorage::Blob.find_by(key: blob_key)
            if blob
              # Only update if it's different from current
              current_blob_key = review.custom_cover.attached? ? review.custom_cover.blob.key : nil
              if current_blob_key != blob_key
                review.custom_cover.purge if review.custom_cover.attached?
                review.custom_cover.attach(blob)
              end
            end
          end
        rescue => e
          Rails.logger.error("Error attaching custom cover from URL: #{e.message}")
        end
        # Clear cover_image_id when custom cover is set
        review_params_data[:cover_image_id] = nil if params[:review][:cover_image_id] == ""
      elsif params[:review][:cover_image_id].present? || params[:review][:cover_image_id] == ""
        # User selected an IGDB cover or explicitly cleared - clear custom cover
        if params[:review][:cover_image_id] == ""
          review.custom_cover.purge if review.custom_cover.attached?
        end
      end

      if review.update(review_params_data)
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

    # POST /api/reviews/upload_cover
    def upload_cover
      unless params[:cover]
        render json: { errors: ["No file provided"] }, status: :bad_request
        return
      end

      # Create a blob directly
      blob = ActiveStorage::Blob.create_and_upload!(
        io: params[:cover],
        filename: params[:cover].original_filename,
        content_type: params[:cover].content_type
      )
      
      # Return the URL
      url = Rails.application.routes.url_helpers.rails_blob_path(blob, only_path: true)
      full_url = request.base_url + url
      
      render json: { url: full_url, blob_key: blob.key }, status: :ok
    rescue => e
      Rails.logger.error("Cover upload error: #{e.message}")
      render json: { errors: [e.message] }, status: :internal_server_error
    end

    private

    def review_params
      params.require(:review).permit(:comment, :rating, :igdb_game_id, :cover_image_id, :custom_cover, :custom_cover_url, :custom_cover_blob_key)
    end

    # Centralized serializer for plain JSON
    def serialize_review(review)
      custom_cover_url = nil
      if review.custom_cover.attached?
        # Return full URL for custom cover
        path = Rails.application.routes.url_helpers.rails_blob_path(review.custom_cover, only_path: true)
        custom_cover_url = request.base_url + path
      end
      
      {
        id: review.id,
        comment: review.comment,
        rating: review.rating,
        igdb_game_id: review.igdb_game_id,
        cover_image_id: review.cover_image_id,
        custom_cover_url: custom_cover_url,
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
