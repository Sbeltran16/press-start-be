module Api
  class ReviewCommentsController < ApplicationController
    before_action :authenticate_user!, only: [:create, :destroy]

    # GET /api/reviews/:review_id/comments
    def index
      review = Review.find(params[:review_id])
      comments = review.review_comments
                       .includes(:user)
                       .order(created_at: :asc)

      render json: comments.map { |comment|
        serialize_comment(comment)
      }, status: :ok
    end

    # POST /api/reviews/:review_id/comments
    def create
      review = Review.find(params[:review_id])
      comment = review.review_comments.build(comment_params)
      comment.user = current_user

      if comment.save
        render json: serialize_comment(comment), status: :created
      else
        render json: { errors: comment.errors.full_messages }, status: :unprocessable_entity
      end
    end

    # DELETE /api/reviews/:review_id/comments/:id
    def destroy
      review = Review.find(params[:review_id])
      comment = review.review_comments.find(params[:id])

      # Only allow the comment owner to delete
      if comment.user_id == current_user.id
        comment.destroy
        render json: { message: "Comment deleted" }, status: :ok
      else
        render json: { errors: ["Not authorized"] }, status: :forbidden
      end
    end

    private

    def comment_params
      params.permit(:content)
    end

    def serialize_comment(comment)
      {
        id: comment.id,
        content: comment.content,
        user: {
          id: comment.user.id,
          username: comment.user.username,
          profile_picture_url: comment.user.profile_picture_url
        },
        created_at: comment.created_at.iso8601
      }
    end
  end
end

