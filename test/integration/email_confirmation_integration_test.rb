require "test_helper"

class EmailConfirmationIntegrationTest < ActionDispatch::IntegrationTest
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

  test "should send confirmation email when user signs up with Gmail" do
    ActionMailer::Base.deliveries.clear
    assert_emails 1 do
      post "/signup", params: {
        user: {
          email: "newuser@gmail.com",
          username: "gmailuser",
          password: "password123",
          password_confirmation: "password123"
        }
      }, as: :json
    end

    assert_response :success
    email = ActionMailer::Base.deliveries.first
    assert_equal ["newuser@gmail.com"], email.to
    assert_equal "Confirm your Press Start account", email.subject
  end

  test "should send confirmation email when user signs up with Yahoo" do
    ActionMailer::Base.deliveries.clear
    assert_emails 1 do
      post "/signup", params: {
        user: {
          email: "newuser@yahoo.com",
          username: "yahoouser",
          password: "password123",
          password_confirmation: "password123"
        }
      }, as: :json
    end

    assert_response :success
    email = ActionMailer::Base.deliveries.first
    assert_equal ["newuser@yahoo.com"], email.to
  end

  test "should send confirmation email when user signs up with Outlook" do
    ActionMailer::Base.deliveries.clear
    assert_emails 1 do
      post "/signup", params: {
        user: {
          email: "newuser@outlook.com",
          username: "outlookuser",
          password: "password123",
          password_confirmation: "password123"
        }
      }, as: :json
    end

    assert_response :success
    email = ActionMailer::Base.deliveries.first
    assert_equal ["newuser@outlook.com"], email.to
  end

  test "should send confirmation email when user signs up with custom domain" do
    ActionMailer::Base.deliveries.clear
    assert_emails 1 do
      post "/signup", params: {
        user: {
          email: "user@example.com",
          username: "customuser",
          password: "password123",
          password_confirmation: "password123"
        }
      }, as: :json
    end

    assert_response :success
    email = ActionMailer::Base.deliveries.first
    assert_equal ["user@example.com"], email.to
  end

  test "should include confirmation token in email" do
    post "/signup", params: {
      user: {
        email: "test@example.com",
        username: "testuser",
        password: "password123",
        password_confirmation: "password123"
      }
    }, as: :json

    assert_response :success
    
    user = User.find_by(email: "test@example.com")
    assert_not_nil user
    assert_not_nil user.confirmation_token
    
    email = ActionMailer::Base.deliveries.first
    email_body = email.html_part ? email.html_part.body.to_s : email.body.to_s
    assert_includes email_body, user.confirmation_token
    assert_includes email_body, "https://pressstart.gg/verify-email"
  end

  test "should send emails to multiple users with different providers" do
    ActionMailer::Base.deliveries.clear
    users_data = [
      { email: "user1@gmail.com", username: "user1" },
      { email: "user2@yahoo.com", username: "user2" },
      { email: "user3@outlook.com", username: "user3" },
      { email: "user4@hotmail.com", username: "user4" },
      { email: "user5@example.com", username: "user5" }
    ]

    assert_emails users_data.length do
      users_data.each do |data|
        post "/signup", params: {
          user: {
            email: data[:email],
            username: data[:username],
            password: "password123",
            password_confirmation: "password123"
          }
        }, as: :json
        assert_response :success
      end
    end

    # Verify all emails were sent to correct addresses
    users_data.each do |data|
      sent_email = ActionMailer::Base.deliveries.find { |e| e.to.include?(data[:email]) }
      assert_not_nil sent_email, "Email not sent to #{data[:email]}"
      assert_equal [data[:email]], sent_email.to
      # Verify token is in email
      user = User.find_by(email: data[:email])
      if user && user.confirmation_token
        email_body = sent_email.html_part ? sent_email.html_part.body.to_s : sent_email.body.to_s
        assert_includes email_body, user.confirmation_token
      end
    end
  end

  test "should allow user to confirm email from any provider" do
    # Create user and send confirmation email
    user = User.create!(
      email: "test@example.com",
      username: "testuser",
      password: "password123"
    )
    user.generate_confirmation_token!
    token = user.confirmation_token

    # Simulate email being sent
    UserMailer.confirmation_instructions(user, token).deliver_now
    
    # User clicks confirmation link
    get "/api/email_confirmations/confirm?confirmation_token=#{token}", as: :json
    
    assert_response :success
    user.reload
    assert user.confirmed?, "User should be confirmed after clicking link"
  end
end

