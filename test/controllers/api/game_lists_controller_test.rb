require "test_helper"

class Api::GameListsControllerTest < ActionDispatch::IntegrationTest
  def setup
    @user = User.create!(
      email: "test@example.com",
      username: "testuser",
      password: "password123"
    )
    @user.confirm # Confirm user so they can authenticate
    
    # Get JWT token for authentication
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
    
    @game_list = GameList.create!(
      user: @user,
      name: "My Test List"
    )
  end

  test "should create game list with valid params" do
    assert_difference "GameList.count", 1 do
      post "/api/game_lists", params: {
        game_list: {
          name: "New List",
          description: "A new list"
        }
      }, headers: @headers, as: :json
    end
    assert_response :success
    
    json_response = JSON.parse(response.body)
    assert_equal "New List", json_response["data"]["name"]
  end

  test "should require authentication to create list" do
    assert_no_difference "GameList.count" do
      post "/api/game_lists", params: {
        game_list: { name: "New List" }
      }, as: :json
    end
    assert_response :unauthorized
  end

  test "should get user's game lists" do
    GameList.create!(user: @user, name: "List 1")
    GameList.create!(user: @user, name: "List 2")
    
    get "/api/game_lists", headers: @headers, as: :json
    assert_response :success
    
    json_response = JSON.parse(response.body)
    assert_equal 3, json_response["data"].length # 2 new + 1 from setup
  end

  test "should get specific game list" do
    get "/api/game_lists/#{@game_list.id}", headers: @headers, as: :json
    assert_response :success
    
    json_response = JSON.parse(response.body)
    assert_equal @game_list.name, json_response["data"]["name"]
  end

  test "should allow public access to view lists" do
    get "/api/game_lists/#{@game_list.id}", as: :json
    assert_response :success
  end

  test "should update game list" do
    patch "/api/game_lists/#{@game_list.id}", params: {
      game_list: { name: "Updated Name" }
    }, headers: @headers, as: :json
    assert_response :success
    
    @game_list.reload
    assert_equal "Updated Name", @game_list.name
  end

  test "should destroy game list" do
    assert_difference "GameList.count", -1 do
      delete "/api/game_lists/#{@game_list.id}", headers: @headers, as: :json
    end
    assert_response :success
  end

  test "should get popular lists without authentication" do
    # Create some lists with likes
    liker = User.create!(
      email: "liker@example.com",
      username: "liker",
      password: "password123"
    )
    liker.confirm
    
    list1 = GameList.create!(user: @user, name: "Popular List 1")
    list2 = GameList.create!(user: @user, name: "Popular List 2")
    
    ListLike.create!(game_list: list1, user: liker)
    ListLike.create!(game_list: list1, user: @user)
    ListLike.create!(game_list: list2, user: liker)
    
    get "/api/game_lists/popular", as: :json
    assert_response :success
    
    json_response = JSON.parse(response.body)
    assert json_response["data"].length > 0
    # list1 should be first (2 likes) then list2 (1 like)
    assert_equal list1.id, json_response["data"].first["id"]
  end
end

