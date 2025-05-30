class Rating < ApplicationRecord
  belongs_to :user
  validates :rating, inclusion: { in: 0.0..5.0 }
  validates :igdb_game_id, presence: true
end