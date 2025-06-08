class ReviewSerializer
  include JSONAPI::Serializer
  attributes :id, :content, :rating, :created_at, :updated_at

  belongs_to :user
  attribute :game do |review|
    {
      id: review.igdb_game_id,
    }
  end
end
