# frozen_string_literal: true

# Daily sync: fetch recent/upcoming releases from IGDB with full fields and upsert.
# Also enriches cached games that have thin data (missing details, screenshots, videos).
class GameCacheSyncService
  RECENT_DAYS = 30
  UPCOMING_DAYS = 90
  RECENT_LIMIT = 200
  UPCOMING_LIMIT = 200
  ENRICH_THIN_BATCH = 50

  class << self
    def run_daily
      Rails.logger.info("[GameCacheSync] Starting daily sync")
      sync_recent_and_upcoming
      enrich_thin_games
      Rails.logger.info("[GameCacheSync] Daily sync finished")
    end

    # Fetch recently released and upcoming games with full fields; upsert into cache.
    def sync_recent_and_upcoming
      return unless ENV["TWITCH_CLIENT_ID"].present? && ENV["TWITCH_CLIENT_SECRET"].present?

      now = Time.now.to_i
      recent_start = (Time.current - RECENT_DAYS.days).to_i
      upcoming_end = (Time.current + UPCOMING_DAYS.days).to_i

      # Recent releases (last N days)
      recent = IgdbService.fetch_games(
        query: "",
        fields: GameCacheService::FULL_GAME_FIELDS,
        where_clause: "where first_release_date >= #{recent_start} & first_release_date <= #{now} & cover != null;",
        limit: RECENT_LIMIT,
        sort: "first_release_date desc"
      )
      if recent&.any?
        GameCacheService.upsert_many_from_igdb(recent)
        Rails.logger.info("[GameCacheSync] Upserted #{recent.size} recent releases")
      end

      # Upcoming releases (next N days)
      upcoming = IgdbService.fetch_games(
        query: "",
        fields: GameCacheService::FULL_GAME_FIELDS,
        where_clause: "where first_release_date > #{now} & first_release_date <= #{upcoming_end} & cover != null;",
        limit: UPCOMING_LIMIT,
        sort: "first_release_date asc"
      )
      if upcoming&.any?
        GameCacheService.upsert_many_from_igdb(upcoming)
        Rails.logger.info("[GameCacheSync] Upserted #{upcoming.size} upcoming releases")
      end
    end

    # Find cached games with thin data (no screenshots / storyline) and re-fetch with full fields.
    def enrich_thin_games
      return unless ENV["TWITCH_CLIENT_ID"].present? && ENV["TWITCH_CLIENT_SECRET"].present?

      # Games where screenshots is missing or empty (jsonb)
      thin = Game.where(
        "data->'screenshots' IS NULL OR data->'screenshots' = '[]'::jsonb"
      ).limit(ENRICH_THIN_BATCH).pluck(:igdb_id)

      return if thin.empty?

      ids = thin.join(",")
      fetched = IgdbService.fetch_games(
        query: "",
        fields: GameCacheService::FULL_GAME_FIELDS,
        where_clause: "where id = (#{ids});",
        limit: thin.size
      )
      if fetched&.any?
        GameCacheService.upsert_many_from_igdb(fetched)
        Rails.logger.info("[GameCacheSync] Enriched #{fetched.size} thin games")
      end
    end
  end
end
