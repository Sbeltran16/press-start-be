class User < ApplicationRecord
  include Devise::JWT::RevocationStrategies::JTIMatcher

  devise :database_authenticatable, :registerable, :validatable,
         :jwt_authenticatable, jwt_revocation_strategy: self

  has_one_attached :profile_picture
  validates :username, presence: true, uniqueness: { case_sensitive: false }
  validates :bio, length: { maximum: 500 }

  #User Reviews Relations
  has_many :reviews
  has_many :review_likes
  has_many :review_comments

  #User Ratings Relations
  has_many :ratings

  ##User Game Interactions
  #Game Likes
  has_many :game_likes, dependent: :destroy
  has_many :liked_games, through: :game_likes, source: :igdb_game

  #Game Plays
  has_many :game_plays, dependent: :destroy
  has_many :played_games, through: :game_plays, source: :igdb_game

  #Favorite Games Relations
  has_many :favorite_games, -> { order(:position) }, dependent: :destroy

  # Follow system
  has_many :active_follows, class_name: "Follow", foreign_key: "follower_id", dependent: :destroy
  has_many :passive_follows, class_name: "Follow", foreign_key: "followed_id", dependent: :destroy

  has_many :following, through: :active_follows, source: :followed
  has_many :followers, through: :passive_follows, source: :follower

  def profile_picture_url
    if profile_picture.attached?
      Rails.application.routes.url_helpers.rails_representation_url(
        profile_picture.variant(resize_to_limit: [200, 200]).processed,
        only_path: false
      )
    else
      nil
    end
  end
end
