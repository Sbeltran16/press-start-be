class ReviewLike < ApplicationRecord
  belongs_to :review
  belongs_to :user
  validates :user_id, uniqueness: { scope: :review_id }
end
