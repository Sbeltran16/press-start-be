class UserSerializer
  include JSONAPI::Serializer
  attributes :id, :email, :username, :bio, :created_at
end