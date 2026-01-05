class AddMissingIndexesForPerformance < ActiveRecord::Migration[7.1]
  def change
    # Add indexes on igdb_game_id columns for better query performance
    # These are used frequently in GameScoreService and other queries
    
    add_index :game_views, :igdb_game_id, unless index_exists?(:game_views, :igdb_game_id)
    add_index :game_likes, :igdb_game_id, unless index_exists?(:game_likes, :igdb_game_id)
    add_index :game_plays, :igdb_game_id, unless index_exists?(:game_plays, :igdb_game_id)
    add_index :reviews, :igdb_game_id, unless index_exists?(:reviews, :igdb_game_id)
    add_index :ratings, :igdb_game_id, unless index_exists?(:ratings, :igdb_game_id)
    
    # Add index on created_at for time-based queries
    add_index :reviews, :created_at, unless index_exists?(:reviews, :created_at)
    add_index :game_lists, :created_at, unless index_exists?(:game_lists, :created_at)
    
    # Add index on follows for better follower/following queries
    add_index :follows, :followed_id, unless index_exists?(:follows, :followed_id)
  end
end

