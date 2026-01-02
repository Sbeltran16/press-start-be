class ActivitiesController < ApplicationController
  before_action :authenticate_user!

  def feed
    following_ids = current_user.following.pluck(:id)

    user_ids = if following_ids.empty?
      User.where.not(id: current_user.id).order("RANDOM()").limit(10).pluck(:id)
    else
      following_ids
    end

    recent_reviews = Review.where(user_id: user_ids)
                           .includes(:user)
                           .order(created_at: :desc)
                           .limit(10)
                           .map do |review|
      {
        type: "review",
        message: "#{review.user.username} reviewed a game",
        review_id: review.id,
        igdb_game_id: review.igdb_game_id,
        rating: review.rating,
        content: review.comment,
        username: review.user.username,
        user_picture_url: review.user.profile_picture_url,
        timestamp: review.created_at
      }
    end

    activities = (recent_reviews)
                  .sort_by { |act| act[:timestamp] }
                  .reverse
                  .take(6)

    render json: { activities: activities }
  end
end
