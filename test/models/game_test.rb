# frozen_string_literal: true

require "test_helper"

class GameTest < ActiveSupport::TestCase
  def setup
    @game = Game.new(
      igdb_id: 12345,
      name: "Test Game",
      slug: "test-game",
      data: { "summary" => "A great game", "cover" => { "image_id" => "abc123" } }
    )
  end

  test "should be valid with valid attributes" do
    assert @game.valid?
  end

  test "should require igdb_id" do
    @game.igdb_id = nil
    assert_not @game.valid?
  end

  test "should require name" do
    @game.name = nil
    assert_not @game.valid?
  end

  test "should require data" do
    @game.data = nil
    assert_not @game.valid?
  end

  test "should require unique igdb_id" do
    @game.save!
    duplicate = Game.new(igdb_id: @game.igdb_id, name: "Other", data: {})
    assert_not duplicate.valid?
  end

  test "to_igdb_response merges id and name into data" do
    @game.save!
    response = @game.to_igdb_response
    assert_equal 12345, response["id"]
    assert_equal "Test Game", response["name"]
    assert_equal "A great game", response["summary"]
    assert_equal "abc123", response.dig("cover", "image_id")
  end

  test "to_igdb_response returns empty hash when data is not a Hash" do
    @game.data = []
    assert_equal [], @game.data
    # Model validation would fail on save; for to_igdb_response we'd get {}
    response = @game.to_igdb_response
    assert_equal({}, response)
  end
end
