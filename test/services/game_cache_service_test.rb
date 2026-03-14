# frozen_string_literal: true

require "test_helper"

class GameCacheServiceTest < ActiveSupport::TestCase
  def setup
    Game.delete_all
  end

  teardown do
    Game.delete_all
  end

  # --- find_by_igdb_id ---
  test "find_by_igdb_id returns nil when id blank" do
    assert_nil GameCacheService.find_by_igdb_id(nil)
    assert_nil GameCacheService.find_by_igdb_id("")
  end

  test "find_by_igdb_id returns nil when game not in cache" do
    assert_nil GameCacheService.find_by_igdb_id(99999)
  end

  test "find_by_igdb_id returns game hash when in cache" do
    Game.create!(igdb_id: 100, name: "Cached", slug: "cached", data: { "summary" => "Hi" })
    result = GameCacheService.find_by_igdb_id(100)
    assert result.is_a?(Hash)
    assert_equal 100, result["id"]
    assert_equal "Cached", result["name"]
    assert_equal "Hi", result["summary"]
  end

  # --- upsert_from_igdb ---
  test "upsert_from_igdb returns nil for invalid payload" do
    assert_nil GameCacheService.upsert_from_igdb(nil)
    assert_nil GameCacheService.upsert_from_igdb({})
    assert_nil GameCacheService.upsert_from_igdb("id" => nil)
  end

  test "upsert_from_igdb creates new game" do
    payload = { "id" => 200, "name" => "New Game", "slug" => "new-game", "summary" => "Fun" }
    record = GameCacheService.upsert_from_igdb(payload)
    assert record.persisted?
    assert_equal 200, record.igdb_id
    assert_equal "New Game", record.name
    assert_equal "Fun", record.data["summary"]
  end

  test "upsert_from_igdb deep merges and does not overwrite rich data with thin" do
    Game.create!(
      igdb_id: 300,
      name: "Rich",
      slug: "rich",
      data: {
        "summary" => "Original summary",
        "screenshots" => [{ "image_id" => "scr1" }],
        "storyline" => "Long storyline"
      }
    )
    thin_payload = { "id" => 300, "name" => "Rich", "summary" => "New summary" }
    GameCacheService.upsert_from_igdb(thin_payload)
    game = Game.find_by(igdb_id: 300)
    assert_equal "New summary", game.data["summary"]
    assert_equal [{ "image_id" => "scr1" }], game.data["screenshots"]
    assert_equal "Long storyline", game.data["storyline"]
  end

  test "deep_merge_preserving_existing keeps existing when new value blank" do
    existing = { "a" => 1, "b" => { "x" => 10 }, "c" => [1, 2] }
    new_hash = { "a" => 2, "b" => {}, "c" => nil, "d" => "new" }
    result = GameCacheService.deep_merge_preserving_existing(existing, new_hash)
    assert_equal 2, result["a"]
    assert_equal 10, result.dig("b", "x")
    assert_equal [1, 2], result["c"]
    assert_equal "new", result["d"]
  end

  # --- thin? ---
  test "thin? returns true for hash with no screenshots videos storyline" do
    assert GameCacheService.thin?({})
    assert GameCacheService.thin?("screenshots" => [], "videos" => nil)
    assert GameCacheService.thin?("name" => "Game")
  end

  test "thin? returns false when enriched_at present" do
    assert_not GameCacheService.thin?("enriched_at" => Time.current.to_i)
  end

  test "thin? returns false when screenshots or videos or storyline present" do
    assert_not GameCacheService.thin?("screenshots" => [{ "id" => 1 }])
    assert_not GameCacheService.thin?("videos" => [{ "id" => 1 }])
    assert_not GameCacheService.thin?("storyline" => "Something")
  end

  test "thin? returns true for non-hash" do
    assert GameCacheService.thin?(nil)
  end

  # --- update_external_data ---
  test "update_external_data merges steam_url and external_links into game" do
    Game.create!(igdb_id: 400, name: "Ext", slug: "ext", data: { "summary" => "S" })
    GameCacheService.update_external_data(400, steam_url: "https://store.steampowered.com/app/123/", external_links: [{ "type" => "steam", "url" => "https://store.steampowered.com/app/123/" }])
    game = Game.find_by(igdb_id: 400)
    assert_equal "https://store.steampowered.com/app/123/", game.data["steam_url"]
    assert_equal 1, game.data["external_links"].size
    assert_equal "steam", game.data["external_links"].first["type"]
  end

  # --- find_or_fetch_by_id with block ---
  test "find_or_fetch_by_id returns cached when present" do
    Game.create!(igdb_id: 500, name: "Cached", slug: "cached", data: { "rating" => 90 })
    block_called = false
    result = GameCacheService.find_or_fetch_by_id(500) { block_called = true; [] }
    assert_not block_called
    assert_equal 90, result["rating"]
  end

  test "find_or_fetch_by_id yields and upserts when not in cache" do
    fetched = [{ "id" => 600, "name" => "Fetched", "slug" => "fetched", "summary" => "From IGDB" }]
    result = GameCacheService.find_or_fetch_by_id(600) { fetched }
    assert result.is_a?(Hash)
    assert_equal 600, result["id"]
    assert_equal "Fetched", result["name"]
    assert_equal "From IGDB", result["summary"]
    assert Game.find_by(igdb_id: 600).present?
  end

  test "find_or_fetch_by_id returns nil when not in cache and block returns empty" do
    result = GameCacheService.find_or_fetch_by_id(99998) { [] }
    assert_nil result
  end

  # --- find_or_fetch_batch ---
  test "find_or_fetch_batch returns empty for empty ids" do
    assert_equal [], GameCacheService.find_or_fetch_batch([])
    assert_equal [], GameCacheService.find_or_fetch_batch(nil)
  end

  test "find_or_fetch_batch returns from cache and yields for missing" do
    Game.create!(igdb_id: 701, name: "One", slug: "one", data: { "id" => 701, "name" => "One" })
    fetched_for_missing = nil
    result = GameCacheService.find_or_fetch_batch([701, 702]) do |missing_ids|
      fetched_for_missing = missing_ids
      [{ "id" => 702, "name" => "Two", "slug" => "two", "summary" => "Two" }]
    end
    assert_equal [702], fetched_for_missing
    assert_equal 2, result.size
    assert_equal [701, 702], result.map { |h| h["id"] }.sort
  end

  test "set_enriched_at sets enriched_at in game data" do
    Game.create!(igdb_id: 900, name: "En", slug: "en", data: { "summary" => "S" })
    GameCacheService.set_enriched_at(900)
    game = Game.find_by(igdb_id: 900)
    assert game.data["enriched_at"].present?
  end

  test "find_by_name returns game when name matches case insensitively" do
    Game.create!(igdb_id: 1000, name: "Dead Space", slug: "dead-space", data: { "summary" => "Horror" })
    assert GameCacheService.find_by_name("dead space").present?
    assert_equal 1000, GameCacheService.find_by_name("DEAD SPACE")["id"]
  end

  test "find_by_name returns nil when no match" do
    assert_nil GameCacheService.find_by_name("Nonexistent Game XYZ")
  end

  test "upsert_many_from_igdb creates multiple games" do
    payloads = [
      { "id" => 801, "name" => "A", "slug" => "a", "summary" => "A" },
      { "id" => 802, "name" => "B", "slug" => "b", "summary" => "B" }
    ]
    records = GameCacheService.upsert_many_from_igdb(payloads)
    assert_equal 2, records.size
    assert_equal 2, Game.where(igdb_id: [801, 802]).count
  end
end
