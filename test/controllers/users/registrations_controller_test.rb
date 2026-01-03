require "test_helper"

class Users::RegistrationsControllerTest < ActionDispatch::IntegrationTest
  def setup
    @user_params = {
      user: {
        email: "newuser@example.com",
        username: "newuser",
        password: "password123",
        password_confirmation: "password123"
      }
    }
  end

  test "should create user with valid params" do
    assert_difference "User.count", 1 do
      post "/signup", params: @user_params, as: :json
    end
    assert_response :success
    
    user = User.find_by(email: "newuser@example.com")
    assert_not_nil user
    assert_equal "newuser", user.username
  end

  test "should not create user with invalid email" do
    @user_params[:user][:email] = "invalid-email"
    assert_no_difference "User.count" do
      post "/signup", params: @user_params, as: :json
    end
    assert_response :unprocessable_entity
  end

  test "should not create user with duplicate email" do
    User.create!(
      email: "existing@example.com",
      username: "existing",
      password: "password123"
    )
    @user_params[:user][:email] = "existing@example.com"
    
    assert_no_difference "User.count" do
      post "/signup", params: @user_params, as: :json
    end
    assert_response :unprocessable_entity
  end

  test "should not create user with duplicate username" do
    User.create!(
      email: "user1@example.com",
      username: "testuser",
      password: "password123"
    )
    @user_params[:user][:username] = "testuser"
    
    assert_no_difference "User.count" do
      post "/signup", params: @user_params, as: :json
    end
    assert_response :unprocessable_entity
  end

  test "should not create user with short password" do
    @user_params[:user][:password] = "short"
    @user_params[:user][:password_confirmation] = "short"
    
    assert_no_difference "User.count" do
      post "/signup", params: @user_params, as: :json
    end
    assert_response :unprocessable_entity
  end

  test "should auto-confirm user when SMTP is not configured" do
    original_smtp_username = ENV['SMTP_USERNAME']
    original_smtp_password = ENV['SMTP_PASSWORD']
    ENV['SMTP_USERNAME'] = nil
    ENV['SMTP_PASSWORD'] = nil
    
    post "/signup", params: @user_params, as: :json
    assert_response :success
    
    user = User.find_by(email: "newuser@example.com")
    assert user.confirmed?, "User should be auto-confirmed when SMTP is not configured"
    
    ENV['SMTP_USERNAME'] = original_smtp_username
    ENV['SMTP_PASSWORD'] = original_smtp_password
  end

  test "should return success message on successful signup" do
    post "/signup", params: @user_params, as: :json
    assert_response :success
    
    json_response = JSON.parse(response.body)
    assert_equal 200, json_response["status"]["code"]
    assert_includes json_response["status"]["message"], "Signed up successfully"
  end

  test "should return user data on successful signup" do
    post "/signup", params: @user_params, as: :json
    assert_response :success
    
    json_response = JSON.parse(response.body)
    assert_not_nil json_response["data"]
    assert_equal "newuser", json_response["data"]["username"]
    assert_equal "newuser@example.com", json_response["data"]["email"]
  end
end

