namespace :db do
  desc "Optimize database to reduce memory usage"
  task optimize: :environment do
    puts "🔧 Starting database optimization..."
    
    # Analyze tables to update statistics
    puts "\n1. Analyzing tables..."
    ActiveRecord::Base.connection.tables.each do |table|
      begin
        ActiveRecord::Base.connection.execute("ANALYZE #{table};")
        puts "   ✓ Analyzed #{table}"
      rescue => e
        puts "   ⚠️  Could not analyze #{table}: #{e.message}"
      end
    end
    
    # Vacuum to reclaim space
    puts "\n2. Running VACUUM..."
    begin
      ActiveRecord::Base.connection.execute("VACUUM ANALYZE;")
      puts "   ✓ VACUUM completed"
    rescue => e
      puts "   ⚠️  VACUUM failed: #{e.message}"
    end
    
    # Show table sizes
    puts "\n3. Table sizes:"
    result = ActiveRecord::Base.connection.execute(<<-SQL)
      SELECT 
        schemaname,
        tablename,
        pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) AS size,
        pg_total_relation_size(schemaname||'.'||tablename) AS size_bytes
      FROM pg_tables
      WHERE schemaname = 'public'
      ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC
      LIMIT 10;
    SQL
    
    result.each do |row|
      puts "   #{row['tablename']}: #{row['size']}"
    end
    
    # Show index sizes
    puts "\n4. Largest indexes:"
    index_result = ActiveRecord::Base.connection.execute(<<-SQL)
      SELECT 
        schemaname,
        tablename,
        indexname,
        pg_size_pretty(pg_relation_size(indexrelid)) AS index_size
      FROM pg_stat_user_indexes
      ORDER BY pg_relation_size(indexrelid) DESC
      LIMIT 10;
    SQL
    
    index_result.each do |row|
      puts "   #{row['indexname']} on #{row['tablename']}: #{row['index_size']}"
    end
    
    puts "\n✅ Database optimization complete!"
  end
  
  desc "Show database memory usage statistics"
  task memory_stats: :environment do
    puts "📊 Database Memory Statistics\n\n"
    
    # Connection count
    connections = ActiveRecord::Base.connection.execute(<<-SQL)
      SELECT count(*) as count FROM pg_stat_activity WHERE datname = current_database();
    SQL
    puts "Active Connections: #{connections.first['count']}"
    
    # Database size
    db_size = ActiveRecord::Base.connection.execute(<<-SQL)
      SELECT pg_size_pretty(pg_database_size(current_database())) AS size;
    SQL
    puts "Database Size: #{db_size.first['size']}"
    
    # Table sizes
    puts "\n📋 Table Sizes:"
    result = ActiveRecord::Base.connection.execute(<<-SQL)
      SELECT 
        tablename,
        pg_size_pretty(pg_total_relation_size('public.'||tablename)) AS total_size,
        pg_size_pretty(pg_relation_size('public.'||tablename)) AS table_size,
        pg_size_pretty(pg_total_relation_size('public.'||tablename) - pg_relation_size('public.'||tablename)) AS indexes_size
      FROM pg_tables
      WHERE schemaname = 'public'
      ORDER BY pg_total_relation_size('public.'||tablename) DESC;
    SQL
    
    result.each do |row|
      puts "  #{row['tablename']}:"
      puts "    Total: #{row['total_size']}"
      puts "    Table: #{row['table_size']}"
      puts "    Indexes: #{row['indexes_size']}"
    end
    
    # Cache hit ratio
    cache_hit = ActiveRecord::Base.connection.execute(<<-SQL)
      SELECT 
        sum(heap_blks_read) as heap_read,
        sum(heap_blks_hit) as heap_hit,
        CASE 
          WHEN sum(heap_blks_hit) + sum(heap_blks_read) = 0 THEN 0
          ELSE round(100.0 * sum(heap_blks_hit) / (sum(heap_blks_hit) + sum(heap_blks_read)), 2)
        END as cache_hit_ratio
      FROM pg_statio_user_tables;
    SQL
    
    hit_ratio = cache_hit.first
    puts "\n💾 Cache Hit Ratio: #{hit_ratio['cache_hit_ratio']}%"
    if hit_ratio['cache_hit_ratio'].to_f < 90
      puts "   ⚠️  Warning: Cache hit ratio is low. Consider increasing shared_buffers."
    end
  end
end

