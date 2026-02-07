class ActivitiesController < ApplicationController
  before_action :authenticate_user!

  def feed
    # Get users the current user follows (excluding current user)
    following_ids = current_user.following.pluck(:id)

    activities = []

    # Reviews - show friends' reviews if they have friends, otherwise show recent reviews from random users
    # Always exclude current user's own reviews
    if following_ids.empty?
      # No friends - show recent reviews from random users (excluding current user)
      recent_reviews = Review.where.not(user_id: current_user.id)
                             .includes(:user)
                             .order(created_at: :desc)
                             .limit(20)
                             .map do |review|
        {
          type: "review",
          message: "#{review.user.username} reviewed a game",
          review_id: review.id,
          igdb_game_id: review.igdb_game_id,
          rating: review.rating,
          content: review.comment,
          username: review.user.username,
          user_id: review.user.id,
          user_picture_url: review.user.profile_picture_url,
          timestamp: review.created_at
        }
      end
    else
      # Has friends - show reviews from friends only (excluding current user)
      recent_reviews = Review.where(user_id: following_ids)
                             .includes(:user)
                             .order(created_at: :desc)
                             .limit(20)
                             .map do |review|
        {
          type: "review",
          message: "#{review.user.username} reviewed a game",
          review_id: review.id,
          igdb_game_id: review.igdb_game_id,
          rating: review.rating,
          content: review.comment,
          username: review.user.username,
          user_id: review.user.id,
          user_picture_url: review.user.profile_picture_url,
          timestamp: review.created_at
        }
      end
    end

    # Game Likes (only from friends, not current user)
    recent_likes = GameLike.where(user_id: following_ids.empty? ? [] : following_ids)
                           .includes(:user)
                           .order(created_at: :desc)
                           .limit(20)
                           .map do |like|
      {
        type: "game_like",
        message: "#{like.user.username} liked a game",
        igdb_game_id: like.igdb_game_id,
        username: like.user.username,
        user_id: like.user.id,
        user_picture_url: like.user.profile_picture_url,
        timestamp: like.created_at
      }
    end

    # Game Plays (only from friends, not current user)
    recent_plays = GamePlay.where(user_id: following_ids.empty? ? [] : following_ids)
                           .includes(:user)
                           .order(created_at: :desc)
                           .limit(20)
                           .map do |play|
      {
        type: "game_play",
        message: "#{play.user.username} played a game",
        igdb_game_id: play.igdb_game_id,
        username: play.user.username,
        user_id: play.user.id,
        user_picture_url: play.user.profile_picture_url,
        timestamp: play.created_at
      }
    end

    # Lists Created (only from friends, not current user)
    recent_lists = GameList.where(user_id: following_ids.empty? ? [] : following_ids)
                           .includes(:user)
                           .order(created_at: :desc)
                           .limit(20)
                           .map do |list|
      {
        type: "list_created",
        message: "#{list.user.username} created a list",
        list_id: list.id,
        list_name: list.name,
        username: list.user.username,
        user_id: list.user.id,
        user_picture_url: list.user.profile_picture_url,
        timestamp: list.created_at
      }
    end

    # Combine all activities and sort by timestamp
    all_activities = (recent_reviews + recent_likes + recent_plays + recent_lists)
                      .sort_by { |act| act[:timestamp] }
                      .reverse
                      .take(50)

    render json: { activities: all_activities }
  end
end
