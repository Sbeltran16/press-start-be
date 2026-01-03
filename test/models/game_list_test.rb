require "test_helper"

class GameListTest < ActiveSupport::TestCase
  def setup
    @user = User.create!(
      email: "test@example.com",
      username: "testuser",
      password: "password123"
    )
    @game_list = GameList.new(
      user: @user,
      name: "My Favorite Games"
    )
  end

  test "should be valid with valid attributes" do
    assert @game_list.valid?
  end

  test "should require user" do
    @game_list.user = nil
    assert_not @game_list.valid?
  end

  test "should require name" do
    @game_list.name = nil
    assert_not @game_list.valid?
  end

  test "should belong to user" do
    @game_list.save!
    assert_equal @user, @game_list.user
  end

  test "should have many game_list_items" do
    @game_list.save!
    item = GameListItem.create!(
      game_list: @game_list,
      igdb_game_id: 123
    )
    assert_includes @game_list.game_list_items, item
  end

  test "should calculate games_count correctly" do
    @game_list.save!
    GameListItem.create!(game_list: @game_list, igdb_game_id: 123)
    GameListItem.create!(game_list: @game_list, igdb_game_id: 456)
    assert_equal 2, @game_list.games_count
  end

  test "should return first_game_id when games exist" do
    @game_list.save!
    GameListItem.create!(game_list: @game_list, igdb_game_id: 123)
    GameListItem.create!(game_list: @game_list, igdb_game_id: 456)
    assert_equal 123, @game_list.first_game_id
  end

  test "should return nil for first_game_id when no games" do
    @game_list.save!
    assert_nil @game_list.first_game_id
  end

  test "should have many list_likes" do
    @game_list.save!
    liker = User.create!(
      email: "liker@example.com",
      username: "liker",
      password: "password123"
    )
    like = ListLike.create!(game_list: @game_list, user: liker)
    assert_includes @game_list.list_likes, like
  end

  test "should calculate likes_count correctly" do
    @game_list.save!
    liker1 = User.create!(
      email: "liker1@example.com",
      username: "liker1",
      password: "password123"
    )
    liker2 = User.create!(
      email: "liker2@example.com",
      username: "liker2",
      password: "password123"
    )
    ListLike.create!(game_list: @game_list, user: liker1)
    ListLike.create!(game_list: @game_list, user: liker2)
    assert_equal 2, @game_list.likes_count
  end

  test "should check if liked by user" do
    @game_list.save!
    liker = User.create!(
      email: "liker@example.com",
      username: "liker",
      password: "password123"
    )
    assert_not @game_list.liked_by?(liker)
    ListLike.create!(game_list: @game_list, user: liker)
    assert @game_list.liked_by?(liker)
  end

  test "should destroy associated items when list is destroyed" do
    @game_list.save!
    item = GameListItem.create!(game_list: @game_list, igdb_game_id: 123)
    @game_list.destroy
    assert_nil GameListItem.find_by(id: item.id)
  end
end

