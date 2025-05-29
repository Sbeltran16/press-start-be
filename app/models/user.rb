class User < ApplicationRecord
  include Devise::JWT::RevocationStrategies::JTIMatcher

  devise :database_authenticatable, :registerable, :validatable,
         :jwt_authenticatable, jwt_revocation_strategy: self

  validates :username, presence: true, uniqueness: true
  validates :bio, length: { maximum: 500 }

  #User Reviews Relations
  has_many :reviews
  has_many :review_likes
  has_many :review_comments

  #User Ratings Relations
  has_many :ratings
end
