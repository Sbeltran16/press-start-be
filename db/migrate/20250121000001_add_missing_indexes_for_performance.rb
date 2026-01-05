class AddMissingIndexesForPerformance < ActiveRecord::Migration[7.1]
  def change
    # Add indexes on igdb_game_id columns for better query performance
    # These are used frequently in GameScoreService and other queries
    
    unless index_exists?(:game_views, :igdb_game_id)
      add_index :game_views, :igdb_game_id
    end
    
    unless index_exists?(:game_likes, :igdb_game_id)
      add_index :game_likes, :igdb_game_id
    end
    
    unless index_exists?(:game_plays, :igdb_game_id)
      add_index :game_plays, :igdb_game_id
    end
    
    unless index_exists?(:reviews, :igdb_game_id)
      add_index :reviews, :igdb_game_id
    end
    
    unless index_exists?(:ratings, :igdb_game_id)
      add_index :ratings, :igdb_game_id
    end
    
    # Add index on created_at for time-based queries
    unless index_exists?(:reviews, :created_at)
      add_index :reviews, :created_at
    end
    
    unless index_exists?(:game_lists, :created_at)
      add_index :game_lists, :created_at
    end
    
    # Add index on follows for better follower/following queries
    unless index_exists?(:follows, :followed_id)
      add_index :follows, :followed_id
    end
  end
end

