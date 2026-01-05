require "test_helper"

class Users::SessionsControllerTest < ActionDispatch::IntegrationTest
  def setup
    @user = User.create!(
      email: "test@example.com",
      username: "testuser",
      password: "password123"
    )
  end

  test "should allow login for unconfirmed user" do
    assert_not @user.confirmed?
    
    post "/login", params: {
      user: {
        email: @user.email,
        password: "password123"
      }
    }, as: :json
    
    # Users can now log in even if unconfirmed
    assert_response :success
    assert_not_nil response.headers["Authorization"]
  end

  test "should allow login for confirmed user" do
    @user.confirm
    
    post "/login", params: {
      user: {
        email: @user.email,
        password: "password123"
      }
    }, as: :json
    
    assert_response :success
    assert_not_nil response.headers["Authorization"]
    
    json_response = JSON.parse(response.body)
    assert_equal 200, json_response["status"]["code"]
    assert_equal "testuser", json_response["data"]["username"]
  end

  test "should reject login with wrong password" do
    @user.confirm
    
    post "/login", params: {
      user: {
        email: @user.email,
        password: "wrongpassword"
      }
    }, as: :json
    
    assert_response :unauthorized
  end

  test "should reject login with wrong email" do
    @user.confirm
    
    post "/login", params: {
      user: {
        email: "wrong@example.com",
        password: "password123"
      }
    }, as: :json
    
    assert_response :unauthorized
  end

  test "should return JWT token on successful login" do
    @user.confirm
    
    post "/login", params: {
      user: {
        email: @user.email,
        password: "password123"
      }
    }, as: :json
    
    assert_response :success
    auth_header = response.headers["Authorization"]
    assert_not_nil auth_header, "Authorization header should be present"
    assert auth_header.start_with?("Bearer "), "Authorization header should start with 'Bearer '"
  end
end

