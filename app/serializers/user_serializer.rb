class UserSerializer
  include JSONAPI::Serializer
  attributes :id, :email, :username, :bio, :created_at
  # has_many :reviews
  attribute :followers_count do |user|
    user.followers.count
  end

  attribute :following_count do |user|
    user.following.count
  end
end