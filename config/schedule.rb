# Run with: bundle exec whenever --update-cron
# Removes schedule: bundle exec whenever --clear-cron
# Use -i to set the app name when updating: bundle exec whenever -i press_start

set :output, { error: "log/cron_error.log", standard: "log/cron.log" }
set :environment, ENV["RAILS_ENV"] || "production"
job_type :rake, "cd :path && :environment_variable=:environment bundle exec rake :task :output"

# Daily at 2:00 AM: sync recent/upcoming releases and enrich thin games
every 1.day, at: "2:00 am" do
  rake "game_cache:sync_daily"
end
