class GameScoreService
  # Returns an array of game IDs sorted by popularity score
  # Optimized to use database aggregation instead of loading all records into memory
  def self.top_game_ids(limit: 12)
    # Use database aggregation with limits to reduce memory usage
    views = GameView.group(:igdb_game_id).count
    likes = GameLike.group(:igdb_game_id).count
    plays = GamePlay.group(:igdb_game_id).count
    reviews = Review.group(:igdb_game_id).count

    # Get all unique game IDs from all sources
    all_game_ids = (views.keys + likes.keys + plays.keys + reviews.keys).uniq

    # Calculate scores in memory-efficient way
    game_scores = Hash.new(0)
    all_game_ids.each do |game_id|
      game_scores[game_id] += (views[game_id] || 0) * 1
      game_scores[game_id] += (likes[game_id] || 0) * 2
      game_scores[game_id] += (plays[game_id] || 0) * 3
      game_scores[game_id] += (reviews[game_id] || 0) * 4
    end

    game_scores.sort_by { |_, score| -score }.map(&:first).take(limit)
  end

  # Return a hash {game_id => score} for a set of game IDs
  def self.scores_for(game_ids)
    views = GameView.where(igdb_game_id: game_ids).group(:igdb_game_id).count
    likes = GameLike.where(igdb_game_id: game_ids).group(:igdb_game_id).count
    plays = GamePlay.where(igdb_game_id: game_ids).group(:igdb_game_id).count
    reviews = Review.where(igdb_game_id: game_ids).group(:igdb_game_id).count

    scores = Hash.new(0)
    game_ids.each do |id|
      scores[id] += (views[id] || 0) * 1
      scores[id] += (likes[id] || 0) * 2
      scores[id] += (plays[id] || 0) * 3
      scores[id] += (reviews[id] || 0) * 4
    end
    scores
  end
end
