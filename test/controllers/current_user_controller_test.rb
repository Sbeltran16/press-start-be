require "test_helper"

class CurrentUserControllerTest < ActionDispatch::IntegrationTest
  def setup
    @user = User.create!(
      email: "test@example.com",
      username: "testuser",
      password: "password123"
    )
    @user.confirm
    
    # Get JWT token
    post "/login", params: {
      user: {
        email: @user.email,
        password: "password123"
      }
    }, as: :json
    
    @token = response.headers["Authorization"]&.split(" ")&.last
    @headers = {
      "Authorization" => "Bearer #{@token}",
      "Content-Type" => "application/json"
    }
  end

  test "should get current user" do
    get "/me", headers: @headers, as: :json
    assert_response :success
    
    json_response = JSON.parse(response.body)
    assert_equal @user.id, json_response["data"]["id"]
    assert_equal @user.username, json_response["data"]["username"]
  end

  test "should require authentication" do
    get "/me", as: :json
    assert_response :unauthorized
  end
end
