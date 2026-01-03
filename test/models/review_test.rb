require "test_helper"

class ReviewTest < ActiveSupport::TestCase
  def setup
    @user = User.create!(
      email: "test@example.com",
      username: "testuser",
      password: "password123"
    )
    @review = Review.new(
      user: @user,
      igdb_game_id: 123,
      rating: 5,
      comment: "Great game!"
    )
  end

  test "should be valid with valid attributes" do
    assert @review.valid?
  end

  test "should require user" do
    @review.user = nil
    assert_not @review.valid?
  end

  test "should require igdb_game_id" do
    @review.igdb_game_id = nil
    assert_not @review.valid?
  end

  test "should require rating" do
    @review.rating = nil
    assert_not @review.valid?
  end

  test "should validate rating is between 0 and 5" do
    # Model allows 0.0 to 5.0
    @review.rating = -1
    assert_not @review.valid?
    
    @review.rating = 6
    assert_not @review.valid?
    
    @review.rating = 0
    assert @review.valid?
    
    @review.rating = 3
    assert @review.valid?
    
    @review.rating = 5
    assert @review.valid?
  end

  test "should belong to user" do
    @review.save!
    assert_equal @user, @review.user
  end

  test "should have many review_likes" do
    @review.save!
    liker = User.create!(
      email: "liker@example.com",
      username: "liker",
      password: "password123"
    )
    like = ReviewLike.create!(review: @review, user: liker)
    assert_includes @review.review_likes, like
  end

  test "should have many review_comments" do
    @review.save!
    commenter = User.create!(
      email: "commenter@example.com",
      username: "commenter",
      password: "password123"
    )
    comment = ReviewComment.create!(
      review: @review,
      user: commenter,
      content: "Nice review!"
    )
    assert_includes @review.review_comments, comment
  end

  test "should destroy associated likes when review is destroyed" do
    @review.save!
    liker = User.create!(
      email: "liker@example.com",
      username: "liker",
      password: "password123"
    )
    like = ReviewLike.create!(review: @review, user: liker)
    @review.destroy
    assert_nil ReviewLike.find_by(id: like.id)
  end
end
