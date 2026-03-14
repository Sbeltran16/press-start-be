# frozen_string_literal: true

namespace :game_cache do
  desc "Daily sync: fetch recent/upcoming releases from IGDB (full details) and enrich thin cached games. Run daily via cron, e.g. 0 2 * * * cd /path/to/app && bin/rails game_cache:sync_daily"
  task sync_daily: :environment do
    GameCacheSyncService.run_daily
  end
end
