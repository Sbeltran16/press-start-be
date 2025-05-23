class Review < ApplicationRecord
belongs_to :user
has_many :review_likes, dependent: :destroy
has_many :review_comments, dependent: :destroy

validates :rating, inclusion: {in: 0.0..0.5}, numericality: true
validates :igdb_game_id, presence: true
end
