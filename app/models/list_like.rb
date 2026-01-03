class ListLike < ApplicationRecord
  belongs_to :user
  belongs_to :game_list

  validates :user_id, uniqueness: { scope: :game_list_id }
end

