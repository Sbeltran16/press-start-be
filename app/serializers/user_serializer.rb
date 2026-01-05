class UserSerializer
  include JSONAPI::Serializer
  attributes :id, :email, :username, :bio, :location, :created_at

  attribute :email_confirmed do |user|
    # Email confirmation disabled - all users are considered confirmed
    user.confirmed_at.present? || true
  end

  attribute :profile_picture_url do |user|
    begin
      if user.profile_picture.attached?
        Rails.application.routes.url_helpers.rails_representation_url(
          user.profile_picture.variant(resize_to_limit: [200, 200]).processed,
          only_path: false
        )
      else
        nil
      end
    rescue => e
      Rails.logger.error "Error generating profile picture URL: #{e.message}"
      nil
    end
  end

  # has_many :reviews
  attribute :followers_count do |user|
    user.followers.count
  end

  attribute :following_count do |user|
    user.following.count
  end

  attribute :reviews_count do |user|
    user.reviews.count
  end

  attribute :games_count do |user|
    user.reviews.distinct.count(:igdb_game_id)
  end

  attribute :lists_count do |user|
    user.game_lists.count
  end

  attribute :likes_count do |user|
    # Total likes on all reviews by this user
    ReviewLike.joins(:review).where(reviews: { user_id: user.id }).count
  end
end