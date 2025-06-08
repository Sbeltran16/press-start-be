class UserSerializer
  include JSONAPI::Serializer
  attributes :id, :email, :username, :bio, :created_at
  # has_many :reviews
end