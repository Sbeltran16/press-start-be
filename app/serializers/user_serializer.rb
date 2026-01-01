class UserSerializer
  include JSONAPI::Serializer
  attributes :id, :email, :username, :bio, :created_at

  attribute :profile_picture_url do |user|
    if user.profile_picture.attached?
      Rails.application.routes.url_helpers.rails_representation_url(
        user.profile_picture.variant(resize_to_limit: [200, 200]).processed,
        only_path: false
      )
    else
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
end