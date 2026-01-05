class UserMailer < ApplicationMailer
  def confirmation_instructions(user, token, opts = {})
    @user = user
    @token = token
    # Use environment-specific FRONTEND_URL
    frontend_url = ENV['FRONTEND_URL'] || (Rails.env.production? ? 'https://pressstart.gg' : 'http://localhost:3000')
    @confirmation_url = "#{frontend_url}/verify-email?token=#{token}"
    
    Rails.logger.info "UserMailer: Preparing email for #{user.email}"
    Rails.logger.info "UserMailer: Confirmation URL: #{@confirmation_url}"
    Rails.logger.info "UserMailer: From address will be: #{ENV['MAILER_FROM'] || 'noreply@pressstart.gg'}"
    
    begin
      # Set display name to hide personal email
      # Format: "Display Name <email@address.com>"
      from_email = ENV['SMTP_USERNAME'] || ENV['MAILER_FROM'] || 'noreply@pressstart.gg'
      display_name = ENV['MAILER_DISPLAY_NAME'] || 'Press Start'
      from_address = "#{display_name} <#{from_email}>"
      
      mail_result = mail(
        to: @user.email,
        from: from_address,
        reply_to: ENV['MAILER_REPLY_TO'] || from_email,
        subject: 'Confirm your Press Start account'
      )
      Rails.logger.info "UserMailer: Mail object created successfully"
      Rails.logger.info "UserMailer: To=#{mail_result.to.inspect}, From=#{mail_result.from.inspect}"
      mail_result
    rescue => e
      Rails.logger.error "❌ UserMailer: Failed to create mail object for #{user.email}: #{e.class} - #{e.message}"
      Rails.logger.error "Backtrace: #{e.backtrace.first(10).join("\n")}"
      raise e
    end
  end
end

