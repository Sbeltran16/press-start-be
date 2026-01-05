require "test_helper"

class UserMailerTest < ActionMailer::TestCase
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

  # Test email sending to various email providers
  test "should send confirmation email to Gmail address" do
    user = User.create!(
      email: "testuser@gmail.com",
      username: "gmailuser",
      password: "password123"
    )
    user.generate_confirmation_token!
    token = user.confirmation_token

    email = UserMailer.confirmation_instructions(user, token)
    
    assert_emails 1 do
      email.deliver_now
    end
    
    assert_equal ["testuser@gmail.com"], email.to
    assert_equal "Confirm your Press Start account", email.subject
    email_body = email.html_part ? email.html_part.body.to_s : email.body.to_s
    assert_includes email_body, token
    assert_includes email_body, "https://pressstart.gg/verify-email"
  end

  test "should send confirmation email to Yahoo address" do
    user = User.create!(
      email: "testuser@yahoo.com",
      username: "yahoouser",
      password: "password123"
    )
    user.generate_confirmation_token!
    token = user.confirmation_token

    email = UserMailer.confirmation_instructions(user, token)
    
    assert_emails 1 do
      email.deliver_now
    end
    
    assert_equal ["testuser@yahoo.com"], email.to
    email_body = email.html_part ? email.html_part.body.to_s : email.body.to_s
    assert_includes email_body, token
  end

  test "should send confirmation email to Outlook address" do
    user = User.create!(
      email: "testuser@outlook.com",
      username: "outlookuser",
      password: "password123"
    )
    user.generate_confirmation_token!
    token = user.confirmation_token

    email = UserMailer.confirmation_instructions(user, token)
    
    assert_emails 1 do
      email.deliver_now
    end
    
    assert_equal ["testuser@outlook.com"], email.to
    email_body = email.html_part ? email.html_part.body.to_s : email.body.to_s
    assert_includes email_body, token
  end

  test "should send confirmation email to custom domain address" do
    user = User.create!(
      email: "user@example.com",
      username: "customuser",
      password: "password123"
    )
    user.generate_confirmation_token!
    token = user.confirmation_token

    email = UserMailer.confirmation_instructions(user, token)
    
    assert_emails 1 do
      email.deliver_now
    end
    
    assert_equal ["user@example.com"], email.to
    email_body = email.html_part ? email.html_part.body.to_s : email.body.to_s
    assert_includes email_body, token
  end

  test "should send confirmation email to email with plus sign" do
    user = User.create!(
      email: "user+test@gmail.com",
      username: "plususer",
      password: "password123"
    )
    user.generate_confirmation_token!
    token = user.confirmation_token

    email = UserMailer.confirmation_instructions(user, token)
    
    assert_emails 1 do
      email.deliver_now
    end
    
    assert_equal ["user+test@gmail.com"], email.to
    email_body = email.html_part ? email.html_part.body.to_s : email.body.to_s
    assert_includes email_body, token
  end

  test "should send confirmation email to email with dots" do
    user = User.create!(
      email: "first.last.name@example.com",
      username: "dotuser",
      password: "password123"
    )
    user.generate_confirmation_token!
    token = user.confirmation_token

    email = UserMailer.confirmation_instructions(user, token)
    
    assert_emails 1 do
      email.deliver_now
    end
    
    assert_equal ["first.last.name@example.com"], email.to
    email_body = email.html_part ? email.html_part.body.to_s : email.body.to_s
    assert_includes email_body, token
  end

  test "should send confirmation email to email with numbers" do
    user = User.create!(
      email: "user123@example.com",
      username: "numberuser",
      password: "password123"
    )
    user.generate_confirmation_token!
    token = user.confirmation_token

    email = UserMailer.confirmation_instructions(user, token)
    
    assert_emails 1 do
      email.deliver_now
    end
    
    assert_equal ["user123@example.com"], email.to
    email_body = email.html_part ? email.html_part.body.to_s : email.body.to_s
    assert_includes email_body, token
  end

  test "should include correct confirmation URL in email" do
    user = User.create!(
      email: "test@example.com",
      username: "testuser",
      password: "password123"
    )
    user.generate_confirmation_token!
    token = user.confirmation_token

    email = UserMailer.confirmation_instructions(user, token)
    
    expected_url = "https://pressstart.gg/verify-email?token=#{token}"
    email_body = email.html_part ? email.html_part.body.to_s : email.body.to_s
    assert_includes email_body, expected_url
  end

  test "should use correct from address" do
    user = User.create!(
      email: "test@example.com",
      username: "testuser",
      password: "password123"
    )
    user.generate_confirmation_token!
    token = user.confirmation_token

    email = UserMailer.confirmation_instructions(user, token)
    
    assert_equal ["noreply@pressstart.gg"], email.from
  end

  test "should send email with correct subject" do
    user = User.create!(
      email: "test@example.com",
      username: "testuser",
      password: "password123"
    )
    user.generate_confirmation_token!
    token = user.confirmation_token

    email = UserMailer.confirmation_instructions(user, token)
    
    assert_equal "Confirm your Press Start account", email.subject
  end

  test "should handle multiple email sends to different providers" do
    ActionMailer::Base.deliveries.clear
    emails = [
      { email: "user1@gmail.com", username: "user1" },
      { email: "user2@yahoo.com", username: "user2" },
      { email: "user3@outlook.com", username: "user3" },
      { email: "user4@example.com", username: "user4" },
      { email: "user5@customdomain.org", username: "user5" }
    ]

    users = emails.map do |data|
      User.create!(
        email: data[:email],
        username: data[:username],
        password: "password123"
      )
    end
    
    # Clear any emails sent during user creation
    ActionMailer::Base.deliveries.clear

    assert_emails emails.length do
      users.each do |user|
        user.generate_confirmation_token!
        token = user.confirmation_token
        UserMailer.confirmation_instructions(user, token).deliver_now
      end
    end

    # Verify all emails were sent to correct addresses
    delivered_emails = ActionMailer::Base.deliveries
    assert_equal emails.length, delivered_emails.length
    
    emails.each do |data|
      sent_email = delivered_emails.find { |e| e.to.include?(data[:email]) }
      assert_not_nil sent_email, "Email not sent to #{data[:email]}"
      assert_equal [data[:email]], sent_email.to
      email_body = sent_email.html_part ? sent_email.html_part.body.to_s : sent_email.body.to_s
      user = users.find { |u| u.email == data[:email] }
      assert_includes email_body, user.confirmation_token if user
    end
  end

  test "should work with different FRONTEND_URL values" do
    user = User.create!(
      email: "test@example.com",
      username: "testuser",
      password: "password123"
    )
    user.generate_confirmation_token!
    token = user.confirmation_token

    # Test with different frontend URLs
    ['https://pressstart.gg', 'http://localhost:3000', 'https://staging.pressstart.gg'].each do |frontend_url|
      ENV['FRONTEND_URL'] = frontend_url
      email = UserMailer.confirmation_instructions(user, token)
      expected_url = "#{frontend_url}/verify-email?token=#{token}"
      email_body = email.html_part ? email.html_part.body.to_s : email.body.to_s
      assert_includes email_body, expected_url, "URL not found for #{frontend_url}"
    end
  end
end

