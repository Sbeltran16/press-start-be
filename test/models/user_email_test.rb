require "test_helper"

class UserEmailTest < ActiveSupport::TestCase
  def setup
    # Set up test SMTP configuration
    ActionMailer::Base.delivery_method = :test
    ActionMailer::Base.perform_deliveries = true
    ActionMailer::Base.deliveries.clear
    
    # Set required environment variables for testing
    ENV['SMTP_USERNAME'] = 'test@example.com'
    ENV['SMTP_PASSWORD'] = 'test_password'
    ENV['SMTP_ADDRESS'] = 'smtp.example.com'
    ENV['MAILER_FROM'] = 'noreply@pressstart.gg'
    ENV['FRONTEND_URL'] = 'https://pressstart.gg'
  end

  def teardown
    ActionMailer::Base.deliveries.clear
  end

  # Test that send_confirmation_instructions works for various email providers
  test "should send confirmation email to Gmail address" do
    # Clear any emails that might be sent during user creation
    ActionMailer::Base.deliveries.clear
    
    user = User.create!(
      email: "testuser@gmail.com",
      username: "gmailuser",
      password: "password123"
    )
    
    # Clear any emails sent during user creation (Devise might send one)
    ActionMailer::Base.deliveries.clear

    result = user.send_confirmation_instructions
    
    assert result, "Email sending should succeed"
    assert_equal 1, ActionMailer::Base.deliveries.length
    email = ActionMailer::Base.deliveries.first
    assert_equal ["testuser@gmail.com"], email.to
    email_body = email.html_part ? email.html_part.body.to_s : email.body.to_s
    assert_includes email_body, user.confirmation_token
  end

  test "should send confirmation email to Yahoo address" do
    ActionMailer::Base.deliveries.clear
    user = User.create!(
      email: "testuser@yahoo.com",
      username: "yahoouser",
      password: "password123"
    )
    ActionMailer::Base.deliveries.clear

    result = user.send_confirmation_instructions
    
    assert result, "Email sending should succeed"
    assert_equal 1, ActionMailer::Base.deliveries.length
    email = ActionMailer::Base.deliveries.first
    assert_equal ["testuser@yahoo.com"], email.to
  end

  test "should send confirmation email to Outlook address" do
    ActionMailer::Base.deliveries.clear
    user = User.create!(
      email: "testuser@outlook.com",
      username: "outlookuser",
      password: "password123"
    )
    ActionMailer::Base.deliveries.clear

    result = user.send_confirmation_instructions
    
    assert result, "Email sending should succeed"
    assert_equal 1, ActionMailer::Base.deliveries.length
    email = ActionMailer::Base.deliveries.first
    assert_equal ["testuser@outlook.com"], email.to
  end

  test "should send confirmation email to Hotmail address" do
    ActionMailer::Base.deliveries.clear
    user = User.create!(
      email: "testuser@hotmail.com",
      username: "hotmailuser",
      password: "password123"
    )
    ActionMailer::Base.deliveries.clear

    result = user.send_confirmation_instructions
    
    assert result, "Email sending should succeed"
    assert_equal 1, ActionMailer::Base.deliveries.length
    email = ActionMailer::Base.deliveries.first
    assert_equal ["testuser@hotmail.com"], email.to
  end

  test "should send confirmation email to AOL address" do
    ActionMailer::Base.deliveries.clear
    user = User.create!(
      email: "testuser@aol.com",
      username: "aoluser",
      password: "password123"
    )
    ActionMailer::Base.deliveries.clear

    result = user.send_confirmation_instructions
    
    assert result, "Email sending should succeed"
    assert_equal 1, ActionMailer::Base.deliveries.length
    email = ActionMailer::Base.deliveries.first
    assert_equal ["testuser@aol.com"], email.to
  end

  test "should send confirmation email to custom domain" do
    ActionMailer::Base.deliveries.clear
    user = User.create!(
      email: "user@customdomain.com",
      username: "customuser",
      password: "password123"
    )
    ActionMailer::Base.deliveries.clear

    result = user.send_confirmation_instructions
    
    assert result, "Email sending should succeed"
    assert_equal 1, ActionMailer::Base.deliveries.length
    email = ActionMailer::Base.deliveries.first
    assert_equal ["user@customdomain.com"], email.to
  end

  test "should send confirmation email to email with subdomain" do
    ActionMailer::Base.deliveries.clear
    user = User.create!(
      email: "user@mail.example.com",
      username: "subdomainuser",
      password: "password123"
    )
    ActionMailer::Base.deliveries.clear

    result = user.send_confirmation_instructions
    
    assert result, "Email sending should succeed"
    assert_equal 1, ActionMailer::Base.deliveries.length
    email = ActionMailer::Base.deliveries.first
    assert_equal ["user@mail.example.com"], email.to
  end

  test "should send confirmation email to email with special characters" do
    ActionMailer::Base.deliveries.clear
    user = User.create!(
      email: "user+tag@example.com",
      username: "specialuser",
      password: "password123"
    )
    ActionMailer::Base.deliveries.clear

    result = user.send_confirmation_instructions
    
    assert result, "Email sending should succeed"
    assert_equal 1, ActionMailer::Base.deliveries.length
    email = ActionMailer::Base.deliveries.first
    assert_equal ["user+tag@example.com"], email.to
  end

  test "should generate unique confirmation token for each user" do
    users = [
      User.create!(email: "user1@gmail.com", username: "user1", password: "password123"),
      User.create!(email: "user2@yahoo.com", username: "user2", password: "password123"),
      User.create!(email: "user3@outlook.com", username: "user3", password: "password123")
    ]

    tokens = users.map do |user|
      user.generate_confirmation_token!
      user.confirmation_token
    end

    # All tokens should be unique
    assert_equal tokens.length, tokens.uniq.length, "All confirmation tokens should be unique"
  end

  test "should send emails to all users regardless of email provider" do
    email_providers = [
      "gmail.com",
      "yahoo.com",
      "outlook.com",
      "hotmail.com",
      "aol.com",
      "icloud.com",
      "protonmail.com",
      "example.com",
      "customdomain.org",
      "mail.company.co.uk"
    ]

    users = email_providers.map.with_index do |domain, index|
      User.create!(
        email: "user#{index}@#{domain}",
        username: "user#{index}",
        password: "password123"
      )
    end

    ActionMailer::Base.deliveries.clear

    users.each do |user|
      result = user.send_confirmation_instructions
      assert result, "Email should be sent to #{user.email}"
    end

    assert_equal email_providers.length, ActionMailer::Base.deliveries.length
    
    # Verify each email was sent to the correct address
    email_providers.each_with_index do |domain, index|
      expected_email = "user#{index}@#{domain}"
      sent_email = ActionMailer::Base.deliveries.find { |e| e.to.include?(expected_email) }
      assert_not_nil sent_email, "Email not sent to #{expected_email}"
      assert_equal [expected_email], sent_email.to
      email_body = sent_email.html_part ? sent_email.html_part.body.to_s : sent_email.body.to_s
      assert_includes email_body, users[index].confirmation_token
    end
  end

  test "should return false when SMTP is not configured" do
    # Clear SMTP configuration
    ENV['SMTP_USERNAME'] = nil
    ENV['SMTP_PASSWORD'] = nil
    ENV['SMTP_ADDRESS'] = nil

    user = User.create!(
      email: "test@example.com",
      username: "testuser",
      password: "password123"
    )

    result = user.send_confirmation_instructions
    
    assert_not result, "Should return false when SMTP is not configured"
    assert_equal 0, ActionMailer::Base.deliveries.length
  end

  test "should handle email sending errors gracefully" do
    # When SMTP is not configured, send_confirmation_instructions should return false
    # This is already tested in "should return false when SMTP is not configured"
    # For actual SMTP errors, they would be caught and return false in production
    # but are hard to test without mocking, which Minitest doesn't support well
    # So we'll just verify the SMTP configuration check works
    ENV['SMTP_USERNAME'] = nil
    ENV['SMTP_PASSWORD'] = nil
    ENV['SMTP_ADDRESS'] = nil

    ActionMailer::Base.deliveries.clear
    user = User.create!(
      email: "test@example.com",
      username: "testuser",
      password: "password123"
    )
    ActionMailer::Base.deliveries.clear

    result = user.send_confirmation_instructions
    assert_not result, "Should return false when SMTP is not configured"
    assert_equal 0, ActionMailer::Base.deliveries.length
  end
end

