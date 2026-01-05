class User < ApplicationRecord
  include Devise::JWT::RevocationStrategies::JTIMatcher

  devise :database_authenticatable, :registerable, :validatable,
         :jwt_authenticatable,
         jwt_revocation_strategy: self
  
  # Auto-confirm users on creation (email confirmation disabled)
  after_create :auto_confirm_user
  
  def auto_confirm_user
    update_column(:confirmed_at, Time.current) if confirmed_at.nil?
  end
  
  # Keep method for future use (email confirmation disabled for now)
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
      Rails.logger.warn "SMTP check: username=#{smtp_username.present?}, password=#{smtp_password.present?}, address=#{smtp_address.present?}"
      # Don't raise - let the controller handle it
      return false
    end
    
    Rails.logger.info "Attempting to send confirmation email to #{email} for user #{id}"
    
    # Get SMTP settings from Rails config (more reliable than ActionMailer::Base)
    smtp_settings = Rails.application.config.action_mailer.smtp_settings || ActionMailer::Base.smtp_settings
    Rails.logger.info "SMTP settings: address=#{smtp_settings[:address]}, port=#{smtp_settings[:port]}, domain=#{smtp_settings[:domain]}"
    Rails.logger.info "SMTP username: #{ENV['SMTP_USERNAME']}"
    Rails.logger.info "SMTP address from ENV: #{ENV['SMTP_ADDRESS']}"
    Rails.logger.info "SMTP port from ENV: #{ENV['SMTP_PORT']}"
    Rails.logger.info "From address (MAILER_FROM): #{ENV['MAILER_FROM'] || 'noreply@pressstart.gg'}"
    Rails.logger.info "ActionMailer delivery method: #{ActionMailer::Base.delivery_method}"
    
    begin
      mail = UserMailer.confirmation_instructions(self, @raw_confirmation_token)
      Rails.logger.info "Mailer created successfully, attempting delivery..."
      Rails.logger.info "From address: #{mail.from.inspect}, To: #{mail.to.inspect}"
      Rails.logger.info "Email subject: #{mail.subject}"
      
      result = mail.deliver_now
      Rails.logger.info "✅ Email sent successfully to #{email} for user #{id}"
      Rails.logger.info "Email Message ID: #{mail.message_id}"
      Rails.logger.info "Email delivery result: #{result.inspect}"
      Rails.logger.info "Email from: #{mail.from.inspect}, to: #{mail.to.inspect}"
      true
    rescue Net::SMTPAuthenticationError => e
      Rails.logger.error "❌ SMTP Authentication failed for user #{id} (#{email}): #{e.class} - #{e.message}"
      Rails.logger.error "SMTP_USERNAME present: #{ENV['SMTP_USERNAME'].present?}"
      Rails.logger.error "SMTP_PASSWORD present: #{ENV['SMTP_PASSWORD'].present?}"
      Rails.logger.error "SMTP_ADDRESS: #{ENV['SMTP_ADDRESS']}"
      Rails.logger.error "Check SMTP_USERNAME and SMTP_PASSWORD environment variables in Render dashboard"
      false
    rescue Net::SMTPError => e
      Rails.logger.error "❌ SMTP Error for user #{id} (#{email}): #{e.class} - #{e.message}"
      Rails.logger.error "SMTP_ADDRESS: #{ENV['SMTP_ADDRESS']}"
      Rails.logger.error "SMTP_PORT: #{ENV['SMTP_PORT']}"
      Rails.logger.error "Check SMTP_ADDRESS and SMTP_PORT environment variables in Render dashboard"
      false
    rescue => e
      Rails.logger.error "❌ Email delivery failed for user #{id} (#{email}): #{e.class} - #{e.message}"
      Rails.logger.error "Error details: #{e.inspect}"
      Rails.logger.error "Backtrace: #{e.backtrace.first(10).join("\n")}"
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
  validates :username, presence: true, uniqueness: { case_sensitive: false }, length: { minimum: 3, maximum: 30 }
  validates :bio, length: { maximum: 500 }

  #User Reviews Relations
  has_many :reviews, dependent: :destroy
  has_many :review_likes, dependent: :destroy
  has_many :review_comments, dependent: :destroy

  #User Ratings Relations
  has_many :ratings, dependent: :destroy

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
