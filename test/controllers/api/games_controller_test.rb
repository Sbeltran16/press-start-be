# frozen_string_literal: true

require "test_helper"

module Api
  class GamesControllerTest < ActionDispatch::IntegrationTest
    # Use high IDs so we never accidentally hit real IGDB data
    CACHED_IGDB_ID = 99_995_000
    FETCHED_IGDB_ID = 99_995_001

    def setup
      Game.delete_all
    end

    teardown do
      Game.delete_all
    end

    test "show_by_id returns 404 when game not in cache and IGDB returns nothing" do
      IgdbService.stubs(:fetch_games).returns([])
      get "/api/games/999999999"
      assert_response :not_found
    end

    test "show_by_id returns game from cache when present" do
      Game.create!(
        igdb_id: CACHED_IGDB_ID,
        name: "Cached Game",
        slug: "cached-game",
        data: {
          "summary" => "A cached summary",
          "steam_url" => "https://store.steampowered.com/app/5000/",
          "external_links" => [{ "type" => "steam", "url" => "https://store.steampowered.com/app/5000/" }]
        }
      )
      # Stub so we never hit real IGDB if cache lookup failed
      IgdbService.stubs(:fetch_games).returns([])
      get "/api/games/#{CACHED_IGDB_ID}"
      assert_response :success
      json = response.parsed_body
      assert_equal CACHED_IGDB_ID, json["id"]
      assert_equal "Cached Game", json["name"]
      assert_equal "A cached summary", json["summary"]
    end

    test "show_by_id fetches from IGDB when not in cache and returns game" do
      fetched = [{ "id" => FETCHED_IGDB_ID, "name" => "New Game", "slug" => "new-game", "summary" => "From API", "storyline" => "Story" }]
      IgdbService.stubs(:fetch_games).returns(fetched)
      IgdbService.stubs(:fetch_steam_url).returns(nil)
      IgdbService.stubs(:fetch_external_links_formatted).returns([])
      get "/api/games/#{FETCHED_IGDB_ID}"
      assert_response :success
      json = response.parsed_body
      assert_equal FETCHED_IGDB_ID, json["id"]
      assert_equal "New Game", json["name"]
      assert Game.find_by(igdb_id: FETCHED_IGDB_ID).present?
    end
  end
end
