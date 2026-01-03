namespace :email do
  desc "Test email configuration"
  task test: :environment do
    puts "=== Email Configuration Test ==="
    puts ""
    
    # Check environment variables
    puts "Environment Variables:"
    puts "  SMTP_ADDRESS: #{ENV['SMTP_ADDRESS'].present? ? 'SET' : 'NOT SET'}"
    puts "  SMTP_PORT: #{ENV['SMTP_PORT'] || 'NOT SET (default: 587)'}"
    puts "  SMTP_USERNAME: #{ENV['SMTP_USERNAME'].present? ? 'SET' : 'NOT SET'}"
    puts "  SMTP_PASSWORD: #{ENV['SMTP_PASSWORD'].present? ? 'SET' : 'NOT SET'}"
    puts "  SMTP_DOMAIN: #{ENV['SMTP_DOMAIN'] || 'NOT SET'}"
    puts "  MAILER_FROM: #{ENV['MAILER_FROM'] || 'NOT SET (default: noreply@pressstart.gg)'}"
    puts "  FRONTEND_URL: #{ENV['FRONTEND_URL'] || 'NOT SET (default: https://pressstart.gg)'}"
    puts ""
    
    # Check SMTP configuration
    smtp_configured = ENV['SMTP_USERNAME'].present? && 
                     ENV['SMTP_PASSWORD'].present? && 
                     ENV['SMTP_ADDRESS'].present?
    
    if smtp_configured
      puts "✓ SMTP is fully configured"
      puts ""
      puts "SMTP Settings:"
      puts "  Address: #{Rails.application.config.action_mailer.smtp_settings[:address]}"
      puts "  Port: #{Rails.application.config.action_mailer.smtp_settings[:port]}"
      puts "  Domain: #{Rails.application.config.action_mailer.smtp_settings[:domain]}"
      puts "  Authentication: #{Rails.application.config.action_mailer.smtp_settings[:authentication]}"
      puts ""
      
      # Test sending an email
      puts "Testing email send..."
      test_email = ENV['TEST_EMAIL'] || 'test@example.com'
      
      begin
        UserMailer.confirmation_instructions(
          OpenStruct.new(email: test_email, username: 'test'),
          'test-token-123'
        ).deliver_now
        puts "✓ Test email sent successfully to #{test_email}"
      rescue => e
        puts "✗ Failed to send test email: #{e.class} - #{e.message}"
        puts "  #{e.backtrace.first}"
      end
    else
      puts "✗ SMTP is NOT fully configured"
      missing = []
      missing << "SMTP_ADDRESS" unless ENV['SMTP_ADDRESS'].present?
      missing << "SMTP_USERNAME" unless ENV['SMTP_USERNAME'].present?
      missing << "SMTP_PASSWORD" unless ENV['SMTP_PASSWORD'].present?
      puts "  Missing: #{missing.join(', ')}"
      puts ""
      puts "Please set the required environment variables in your production environment."
    end
  end
end

