# frozen_string_literal: true

# Finds game data from the database first; if missing, fetches from IGDB and stores it.
# Uses deep merge so that thin responses (e.g. search) never overwrite rich data
# (details, similar_games, screenshots, videos, etc.).
class GameCacheService
  # Full IGDB fields so every game has details, screenshots, videos, similar_games, etc.
  FULL_GAME_FIELDS = %w[
    id name cover.image_id summary aggregated_rating first_release_date
    storyline genres.name game_engines.name platforms.name release_dates.human
    artworks.image_id screenshots.image_id language_supports.language.name
    videos.video_id videos.name involved_companies.company.name
    similar_games.name similar_games.cover.image_id similar_games.first_release_date
    age_ratings.rating age_ratings.category
  ].join(", ").freeze

  class << self
    # Find a cached game by IGDB id. Returns IGDB-shaped hash or nil.
    def find_by_igdb_id(igdb_id)
      return nil if igdb_id.blank?
      game = Game.find_by(igdb_id: igdb_id.to_i)
      game&.to_igdb_response
    end

    # Find a cached game by name (case-insensitive). Returns IGDB-shaped hash or nil.
    def find_by_name(name)
      return nil if name.blank?
      game = Game.where("name ILIKE ?", name.to_s.strip).first
      game&.to_igdb_response
    end

    # Find a cached game by slug. Returns IGDB-shaped hash or nil.
    def find_by_slug(slug)
      return nil if slug.blank?
      game = Game.find_by(slug: slug.to_s.strip)
      game&.to_igdb_response
    end

    # Store or update a game from an IGDB response hash.
    # Deep-merges into existing data so we never lose details, similar_games, screenshots,
    # videos, etc. when a thinner response (e.g. search/list) is saved later.
    def upsert_from_igdb(payload)
      return nil unless payload.is_a?(Hash) && payload["id"].present?

      id = payload["id"].to_i
      name = payload["name"].to_s.presence || "Unknown"
      slug = payload["slug"].to_s.presence

      game = Game.find_or_initialize_by(igdb_id: id)
      existing_data = game.persisted? ? (game.data || {}) : {}
      # Prefer new values when present, so we don't overwrite rich data with blank/thin data
      merged_data = deep_merge_preserving_existing(existing_data, payload)

      game.assign_attributes(name: name, slug: slug, data: merged_data)
      game.save!
      game
    end

    # Merge external links and steam_url into cached game data (e.g. after fetching from IGDB).
    def update_external_data(igdb_id, steam_url: nil, external_links: nil)
      game = Game.find_by(igdb_id: igdb_id.to_i)
      return unless game

      data = game.data || {}
      data = data.merge("steam_url" => steam_url) if steam_url.present?
      data = data.merge("external_links" => external_links) if external_links.present?
      game.update!(data: data)
    end

    # Deep merge: for each key, use new value if it's "present" (non-blank), else keep existing.
    # This prevents thin API responses from wiping out rich cached data.
    def deep_merge_preserving_existing(existing, new_hash)
      return new_hash if existing.blank?
      return existing if new_hash.blank?

      existing = existing.stringify_keys
      new_hash = new_hash.stringify_keys
      result = existing.dup
      new_hash.each do |key, new_val|
        if result.key?(key) && result[key].is_a?(Hash) && new_val.is_a?(Hash)
          result[key] = deep_merge_preserving_existing(result[key], new_val)
        elsif new_val.present? || new_val == false
          result[key] = new_val
        end
      end
      result
    end

    # Upsert multiple games from IGDB response array. Returns array of Game records.
    def upsert_many_from_igdb(payloads)
      return [] unless payloads.is_a?(Array)

      payloads.filter_map { |p| upsert_from_igdb(p) rescue nil }
    end

    # True if this game hash is missing details/screenshots/videos (was cached from a thin response).
    # Skip if we already ran a full fetch (enriched_at set) so we don't re-fetch games that have no media on IGDB.
    def thin?(game_hash)
      return true unless game_hash.is_a?(Hash)
      return false if game_hash["enriched_at"].present?
      game_hash["screenshots"].blank? && game_hash["videos"].blank? && game_hash["storyline"].blank?
    end

    # Fetch game from IGDB with full fields and upsert. Returns updated game hash or nil.
    # Sets enriched_at so we don't keep re-fetching games that have no screenshots/videos on IGDB.
    def enrich_game(igdb_id)
      result = IgdbService.fetch_games(
        query: "",
        fields: FULL_GAME_FIELDS,
        where_clause: "where id = #{igdb_id.to_i};",
        limit: 1
      )
      return nil unless result.is_a?(Array) && result.first.present?
      upsert_from_igdb(result.first)
      set_enriched_at(igdb_id)
      find_by_igdb_id(igdb_id)
    end

    def set_enriched_at(igdb_id)
      game = Game.find_by(igdb_id: igdb_id.to_i)
      return unless game
      data = (game.data || {}).merge("enriched_at" => Time.current.to_i)
      game.update!(data: data)
    end

    # Get game by IGDB id: from cache or fetch from IGDB, store, and return as hash.
    # Yields to caller to perform the IGDB fetch (caller passes fields, where_clause, etc.).
    def find_or_fetch_by_id(igdb_id, &fetch_block)
      cached = find_by_igdb_id(igdb_id)
      return cached if cached.present?

      result = yield if block_given?
      return nil unless result.is_a?(Array) && result.first.present?

      game_hash = result.first
      upsert_from_igdb(game_hash)
      find_by_igdb_id(igdb_id)
    end

    # Get game by name (search): from cache by name, or fetch from IGDB, store, and return.
    def find_or_fetch_by_name(name, &fetch_block)
      return nil if name.blank?

      decoded = CGI.unescape(name.to_s)
      cached = Game.where("name ILIKE ?", decoded).first
      return cached.to_igdb_response if cached.present?

      result = yield if block_given?
      return nil unless result.is_a?(Array) && result.first.present?

      game_hash = result.first
      upsert_from_igdb(game_hash)
      find_by_igdb_id(game_hash["id"])
    end

    # For a list of IGDB ids: load from cache, collect missing ids, fetch missing from IGDB,
    # upsert them, then return all as array of hashes in the same order as ids.
    def find_or_fetch_batch(igdb_ids, &fetch_block)
      ids = Array(igdb_ids).map(&:to_i).reject(&:zero?).uniq
      return [] if ids.empty?

      records = Game.where(igdb_id: ids).index_by(&:igdb_id)
      missing_ids = ids.reject { |id| records[id].present? }

      if missing_ids.any? && block_given?
        fetched = yield missing_ids
        GameCacheService.upsert_many_from_igdb(Array(fetched))
        records = Game.where(igdb_id: ids).index_by(&:igdb_id)
      end

      ids.filter_map { |id| records[id]&.to_igdb_response }
    end
  end
end
