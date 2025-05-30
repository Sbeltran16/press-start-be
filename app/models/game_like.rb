class GameLike < ApplicationRecord
  belongs_to :user

  validates :igdb_game_id, presence: true
  validates :user_id, uniqueness: { scope: :igdb_game_id }
end

