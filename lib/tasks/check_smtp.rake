namespace :smtp do
  desc "Check SMTP configuration and test email sending"
  task check: :environment do
    puts "=== SMTP Configuration Check ===\n\n"
    
    # Check environment variables
    puts "Environment Variables:"
    puts "  SMTP_ADDRESS: #{ENV['SMTP_ADDRESS'].present? ? "✓ SET (#{ENV['SMTP_ADDRESS']})" : "✗ NOT SET"}"
    puts "  SMTP_PORT: #{ENV['SMTP_PORT'].present? ? "✓ SET (#{ENV['SMTP_PORT']})" : "✗ NOT SET (default: 587)"}"
    puts "  SMTP_USERNAME: #{ENV['SMTP_USERNAME'].present? ? "✓ SET (#{ENV['SMTP_USERNAME']})" : "✗ NOT SET"}"
    puts "  SMTP_PASSWORD: #{ENV['SMTP_PASSWORD'].present? ? "✓ SET (hidden)" : "✗ NOT SET"}"
    puts "  SMTP_DOMAIN: #{ENV['SMTP_DOMAIN'].present? ? "✓ SET (#{ENV['SMTP_DOMAIN']})" : "✗ NOT SET"}"
    puts "  MAILER_FROM: #{ENV['MAILER_FROM'].present? ? "✓ SET (#{ENV['MAILER_FROM']})" : "✗ NOT SET (default: noreply@pressstart.gg)"}"
    puts "  FRONTEND_URL: #{ENV['FRONTEND_URL'].present? ? "✓ SET (#{ENV['FRONTEND_URL']})" : "✗ NOT SET"}"
    puts ""
    
    # Check Rails SMTP configuration
    puts "Rails SMTP Configuration:"
    smtp_settings = Rails.application.config.action_mailer.smtp_settings
    puts "  Delivery Method: #{ActionMailer::Base.delivery_method}"
    puts "  Address: #{smtp_settings[:address]}"
    puts "  Port: #{smtp_settings[:port]}"
    puts "  Domain: #{smtp_settings[:domain]}"
    puts "  Authentication: #{smtp_settings[:authentication]}"
    puts "  Username: #{smtp_settings[:user_name] ? 'SET' : 'NOT SET'}"
    puts "  Password: #{smtp_settings[:password] ? 'SET' : 'NOT SET'}"
    puts ""
    
    # Check if fully configured
    smtp_configured = ENV['SMTP_USERNAME'].present? && 
                     ENV['SMTP_PASSWORD'].present? && 
                     ENV['SMTP_ADDRESS'].present?
    
    if smtp_configured
      puts "✓ SMTP is fully configured"
      puts ""
      puts "Test email sending..."
      test_email = ENV['TEST_EMAIL'] || 'test@example.com'
      
      begin
        UserMailer.confirmation_instructions(
          OpenStruct.new(email: test_email, username: 'test', id: 999),
          'test-token-123'
        ).deliver_now
        puts "✓ Test email sent successfully to #{test_email}"
        puts "  Check your inbox (and spam folder) for the confirmation email"
      rescue => e
        puts "✗ Failed to send test email: #{e.class} - #{e.message}"
        puts "  Error: #{e.inspect}"
        if e.respond_to?(:backtrace)
          puts "  Backtrace: #{e.backtrace.first(3).join("\n  ")}"
        end
      end
    else
      puts "✗ SMTP is NOT fully configured"
      missing = []
      missing << "SMTP_USERNAME" unless ENV['SMTP_USERNAME'].present?
      missing << "SMTP_PASSWORD" unless ENV['SMTP_PASSWORD'].present?
      missing << "SMTP_ADDRESS" unless ENV['SMTP_ADDRESS'].present?
      puts "  Missing: #{missing.join(', ')}"
      puts ""
      puts "To fix: Set these environment variables in your Render dashboard:"
      puts "  - SMTP_ADDRESS (e.g., smtp.gmail.com)"
      puts "  - SMTP_USERNAME (your email or SMTP username)"
      puts "  - SMTP_PASSWORD (your SMTP password or app password)"
    end
  end
end

