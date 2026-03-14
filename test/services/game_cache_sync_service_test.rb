# frozen_string_literal: true

require "test_helper"

class GameCacheSyncServiceTest < ActiveSupport::TestCase
  def setup
    Game.delete_all
    @original_twitch_id = ENV["TWITCH_CLIENT_ID"]
    @original_twitch_secret = ENV["TWITCH_CLIENT_SECRET"]
    ENV["TWITCH_CLIENT_ID"] = "test_id"
    ENV["TWITCH_CLIENT_SECRET"] = "test_secret"
  end

  def teardown
    Game.delete_all
    ENV["TWITCH_CLIENT_ID"] = @original_twitch_id
    ENV["TWITCH_CLIENT_SECRET"] = @original_twitch_secret
  end

  test "run_daily calls sync_recent_and_upcoming and enrich_thin_games" do
    IgdbService.stubs(:fetch_games).returns(nil)
    GameCacheSyncService.run_daily
    assert true
  end

  test "sync_recent_and_upcoming upserts when IgdbService returns recent games" do
    recent_payload = [
      { "id" => 1001, "name" => "Recent Game", "slug" => "recent-game", "first_release_date" => Time.current.to_i - 1.day.to_i, "summary" => "New" }
    ]
    IgdbService.stubs(:fetch_games).returns(recent_payload).then.returns([])
    GameCacheSyncService.sync_recent_and_upcoming
    assert Game.find_by(igdb_id: 1001).present?
  end

  test "sync_recent_and_upcoming does nothing when TWITCH credentials missing" do
    ENV["TWITCH_CLIENT_ID"] = nil
    ENV["TWITCH_CLIENT_SECRET"] = nil
    IgdbService.stubs(:fetch_games).never
    GameCacheSyncService.sync_recent_and_upcoming
    assert_equal 0, Game.count
  end

  test "enrich_thin_games upserts when thin games exist and fetch returns data" do
    Game.create!(igdb_id: 2001, name: "Thin", slug: "thin", data: { "summary" => "Only summary" })
    fetched = [
      { "id" => 2001, "name" => "Thin", "slug" => "thin", "screenshots" => [{ "image_id" => "s1" }], "storyline" => "Story" }
    ]
    IgdbService.stubs(:fetch_games).returns(fetched)
    GameCacheSyncService.enrich_thin_games
    game = Game.find_by(igdb_id: 2001)
    assert game.data["screenshots"].present?
    assert_equal "Story", game.data["storyline"]
  end

  test "enrich_thin_games does nothing when no thin games" do
    Game.create!(
      igdb_id: 2002,
      name: "Rich",
      slug: "rich",
      data: { "screenshots" => [{ "image_id" => "x" }] }
    )
    IgdbService.stubs(:fetch_games).never
    GameCacheSyncService.enrich_thin_games
    assert_equal 1, Game.count
  end
end
