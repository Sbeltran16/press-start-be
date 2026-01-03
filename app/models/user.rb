class User < ApplicationRecord
  include Devise::JWT::RevocationStrategies::JTIMatcher

  devise :database_authenticatable, :registerable, :validatable,
         :jwt_authenticatable, :confirmable,
         jwt_revocation_strategy: self,
         confirmation_keys: [:email]
  
  # Override Devise's confirmation email to use our custom mailer
  def send_confirmation_instructions
    unless @raw_confirmation_token
      generate_confirmation_token!
    end
    
    # Validate SMTP configuration before attempting to send
    smtp_username = ENV['SMTP_USERNAME'].to_s.strip
    smtp_password = ENV['SMTP_PASSWORD'].to_s.strip
    smtp_address = ENV['SMTP_ADDRESS'].to_s.strip
    
    unless smtp_username.present? && smtp_password.present? && smtp_address.present?
      Rails.logger.warn "SMTP not fully configured - cannot send confirmation email for user #{id}"
      # Don't raise - let the controller handle it
      return false
    end
    
    begin
      UserMailer.confirmation_instructions(self, @raw_confirmation_token).deliver_now
      true
    rescue => e
      Rails.logger.error "Email delivery failed for user #{id}: #{e.class} - #{e.message}"
      false
    end
  end
  
  # Override to generate confirmation token
  def generate_confirmation_token!
    self.confirmation_token = Devise.friendly_token
    self.confirmation_sent_at = Time.now.utc
    @raw_confirmation_token = confirmation_token
    unless save(validate: false)
      Rails.logger.error "Failed to save confirmation token: #{errors.full_messages.inspect}"
      raise "Failed to generate confirmation token"
    end
  end

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

  #Backlog Games Relations
  has_many :backlog_games, dependent: :destroy

  # Follow system
  has_many :active_follows, class_name: "Follow", foreign_key: "follower_id", dependent: :destroy
  has_many :passive_follows, class_name: "Follow", foreign_key: "followed_id", dependent: :destroy

  has_many :following, through: :active_follows, source: :followed
  has_many :followers, through: :passive_follows, source: :follower

  # Game Lists
  has_many :game_lists, dependent: :destroy

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
