class FavoriteGame < ApplicationRecord
  belongs_to :user

  validates :igdb_game_id, presence: true, uniqueness: { scope: :user_id }
end
