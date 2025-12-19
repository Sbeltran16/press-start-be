class ReviewSerializer
  include JSONAPI::Serializer
  attributes :id, :comment, :rating, :created_at, :updated_at

  attribute :likes_count do |review|
    review.review_likes.count
  end

  attribute :liked_by_current_user do |review, params|
    params&.dig(:current_user).present? && review.review_likes.exists?(user_id: params[:current_user].id)
  end

  belongs_to :user
  attribute :game do |review|
    { id: review.igdb_game_id }
  end
end
