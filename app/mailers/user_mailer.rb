class UserMailer < ApplicationMailer
  def confirmation_instructions(user, token, opts = {})
    @user = user
    @token = token
    # Use environment-specific FRONTEND_URL
    frontend_url = ENV['FRONTEND_URL'] || (Rails.env.production? ? 'https://pressstart.gg' : 'http://localhost:3000')
    @confirmation_url = "#{frontend_url}/verify-email?token=#{token}"
    
    mail(
      to: @user.email,
      subject: 'Confirm your Press Start account'
    )
  end
end

