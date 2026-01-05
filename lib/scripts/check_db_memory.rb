# Script to check database memory usage
# Run this in Rails console: load 'lib/scripts/check_db_memory.rb'

puts "📊 Database Memory Usage Check\n\n"

# Database size
db_size = ActiveRecord::Base.connection.execute(<<-SQL)
  SELECT pg_size_pretty(pg_database_size(current_database())) AS size;
SQL
puts "Database Size: #{db_size.first['size']}"

# Table sizes
puts "\n📋 Largest Tables:"
result = ActiveRecord::Base.connection.execute(<<-SQL)
  SELECT 
    tablename,
    pg_size_pretty(pg_total_relation_size('public.'||tablename)) AS size,
    pg_total_relation_size('public.'||tablename) AS size_bytes
  FROM pg_tables
  WHERE schemaname = 'public'
  ORDER BY pg_total_relation_size('public.'||tablename) DESC
  LIMIT 10;
SQL

result.each do |row|
  puts "  #{row['tablename']}: #{row['size']}"
end

# Row counts
puts "\n📊 Row Counts:"
tables = ['users', 'reviews', 'ratings', 'game_likes', 'game_plays', 'game_views', 'game_lists', 'follows']
tables.each do |table|
  count = ActiveRecord::Base.connection.execute("SELECT COUNT(*) FROM #{table}").first['count']
  puts "  #{table}: #{count.to_s.reverse.gsub(/(\d{3})(?=\d)/, '\\1,').reverse}"
end

# Missing indexes check
puts "\n🔍 Checking for missing indexes..."
missing_indexes = []
missing_indexes << "game_views.igdb_game_id" unless ActiveRecord::Base.connection.index_exists?(:game_views, :igdb_game_id)
missing_indexes << "reviews.igdb_game_id" unless ActiveRecord::Base.connection.index_exists?(:reviews, :igdb_game_id)
missing_indexes << "reviews.created_at" unless ActiveRecord::Base.connection.index_exists?(:reviews, :created_at)
missing_indexes << "follows.followed_id" unless ActiveRecord::Base.connection.index_exists?(:follows, :followed_id)

if missing_indexes.any?
  puts "  ⚠️  Missing indexes detected:"
  missing_indexes.each { |idx| puts "    - #{idx}" }
  puts "\n  Run: rails db:migrate (to add missing indexes)"
else
  puts "  ✅ All recommended indexes exist"
end

puts "\n💡 To optimize database, run: rails db:optimize"

