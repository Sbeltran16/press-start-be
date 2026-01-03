class GameList < ApplicationRecord
  belongs_to :user
  has_many :game_list_items, -> { order(:position) }, dependent: :destroy
  has_many :list_likes, dependent: :destroy

  validates :name, presence: true
  validates :name, uniqueness: { scope: :user_id, case_sensitive: false }

  def first_game_id
    game_list_items.order(:position).first&.igdb_game_id
  end

  def games_count
    game_list_items.count
  end

  def likes_count
    list_likes.count
  end

  def liked_by?(user)
    return false unless user
    list_likes.exists?(user_id: user.id)
  end
end

