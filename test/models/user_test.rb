require "test_helper"

class UserTest < ActiveSupport::TestCase
  def setup
    @user = User.new(
      email: "test@example.com",
      username: "testuser",
      password: "password123",
      password_confirmation: "password123"
    )
  end

  test "should be valid with valid attributes" do
    assert @user.valid?
  end

  test "should require email" do
    @user.email = nil
    assert_not @user.valid?
    assert_includes @user.errors[:email], "can't be blank"
  end

  test "should require username" do
    @user.username = nil
    assert_not @user.valid?
    assert_includes @user.errors[:username], "can't be blank"
  end

  test "should require unique username (case insensitive)" do
    @user.save!
    duplicate_user = User.new(
      email: "another@example.com",
      username: "TESTUSER",
      password: "password123"
    )
    assert_not duplicate_user.valid?
    assert_includes duplicate_user.errors[:username], "has already been taken"
  end

  test "should require unique email" do
    @user.save!
    duplicate_user = User.new(
      email: "test@example.com",
      username: "anotheruser",
      password: "password123"
    )
    assert_not duplicate_user.valid?
  end

  test "should validate bio length" do
    @user.bio = "a" * 501
    assert_not @user.valid?
    assert_includes @user.errors[:bio], "is too long (maximum is 500 characters)"
  end

  test "should allow bio up to 500 characters" do
    @user.bio = "a" * 500
    assert @user.valid?
  end

  test "should generate confirmation token" do
    @user.save!
    @user.generate_confirmation_token!
    assert_not_nil @user.confirmation_token
    assert_not_nil @user.confirmation_sent_at
  end

  test "should not be confirmed by default" do
    @user.save!
    assert_not @user.confirmed?
  end

  test "should be confirmed after confirmation" do
    @user.save!
    @user.confirm
    assert @user.confirmed?
    assert_not_nil @user.confirmed_at
  end

  test "should have many game_lists" do
    @user.save!
    game_list = GameList.create!(user: @user, name: "My List")
    assert_includes @user.game_lists, game_list
  end

  test "should have many reviews" do
    @user.save!
    review = Review.create!(
      user: @user,
      igdb_game_id: 123,
      rating: 5,
      comment: "Great game"
    )
    assert_includes @user.reviews, review
  end

  test "should destroy associated game_lists when user is destroyed" do
    @user.save!
    game_list = GameList.create!(user: @user, name: "My List")
    @user.destroy
    assert_nil GameList.find_by(id: game_list.id)
  end

  test "should have followers and following associations" do
    @user.save!
    follower = User.create!(
      email: "follower@example.com",
      username: "follower",
      password: "password123"
    )
    follow = Follow.create!(follower: follower, followed: @user)
    
    @user.reload
    follower.reload
    
    assert_includes @user.followers, follower
    assert_includes follower.following, @user
  end
end
