require "test_helper"

class Api::EmailConfirmationsControllerTest < ActionDispatch::IntegrationTest
  def setup
    @user = User.create!(
      email: "test@example.com",
      username: "testuser",
      password: "password123"
    )
    @user.generate_confirmation_token!
    @token = @user.confirmation_token
  end

  test "should confirm email with valid token" do
    assert_not @user.confirmed?
    
    # Use query string format for GET request
    get "/api/email_confirmations/confirm?confirmation_token=#{@token}", as: :json
    assert_response :success
    
    @user.reload
    assert @user.confirmed?
  end

  test "should return error with invalid token" do
    get "/api/email_confirmations/confirm?confirmation_token=invalid_token", as: :json
    assert_response :not_found
    
    json_response = JSON.parse(response.body)
    assert_equal "Invalid confirmation token", json_response["error"]
  end

  test "should return error with missing token" do
    get "/api/email_confirmations/confirm", as: :json
    assert_response :bad_request
    
    json_response = JSON.parse(response.body)
    assert_equal "Confirmation token is required", json_response["error"]
  end

  test "should return success if email already confirmed" do
    @user.confirm
    
    get "/api/email_confirmations/confirm?confirmation_token=#{@token}", as: :json
    assert_response :success
    
    json_response = JSON.parse(response.body)
    assert json_response["email_confirmed"]
    assert_equal "Email already confirmed", json_response["message"]
  end

  test "should return JWT token after successful confirmation" do
    get "/api/email_confirmations/confirm?confirmation_token=#{@token}", as: :json
    assert_response :success
    
    json_response = JSON.parse(response.body)
    assert_not_nil json_response["token"]
  end

  test "should resend confirmation email" do
    post "/api/email_confirmations/resend", params: { email: @user.email }, as: :json
    assert_response :success
    
    json_response = JSON.parse(response.body)
    assert_includes json_response["message"], "Confirmation email has been sent"
  end

  test "should return success even if email doesn't exist (security)" do
    post "/api/email_confirmations/resend", params: { email: "nonexistent@example.com" }, as: :json
    assert_response :success
    # Should not reveal if email exists or not
  end

  test "should return error if email parameter is missing" do
    post "/api/email_confirmations/resend", params: {}, as: :json
    assert_response :bad_request
    
    json_response = JSON.parse(response.body)
    assert_equal "Email is required", json_response["error"]
  end
end

