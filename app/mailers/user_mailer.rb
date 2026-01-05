class UserMailer < ApplicationMailer
  def confirmation_instructions(user, token, opts = {})
    @user = user
    @token = token
    # Use environment-specific FRONTEND_URL
    frontend_url = ENV['FRONTEND_URL'] || (Rails.env.production? ? 'https://pressstart.gg' : 'http://localhost:3000')
    @confirmation_url = "#{frontend_url}/verify-email?token=#{token}"
    
    begin
      mail(
        to: @user.email,
        subject: 'Confirm your Press Start account'
      )
    rescue => e
      Rails.logger.error "Failed to create mail object for #{user.email}: #{e.class} - #{e.message}"
      Rails.logger.error "Backtrace: #{e.backtrace.first(10).join("\n")}"
      raise e
    end
  end
end

