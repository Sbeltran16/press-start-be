class GameListItem < ApplicationRecord
  belongs_to :game_list

  validates :igdb_game_id, presence: true
  validates :igdb_game_id, uniqueness: { scope: :game_list_id }
end

