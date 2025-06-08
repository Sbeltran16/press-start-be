class GameScoreService
  # Returns an array of game IDs sorted by popularity score
  def self.top_game_ids(limit: 12)
    views = GameView.group(:igdb_game_id).count
    likes = GameLike.group(:igdb_game_id).count
    plays = GamePlay.group(:igdb_game_id).count
    reviews = Review.group(:igdb_game_id).count

    game_scores = Hash.new(0)
    views.each { |game_id, count| game_scores[game_id] += count * 1 }
    likes.each { |game_id, count| game_scores[game_id] += count * 2 }
    plays.each { |game_id, count| game_scores[game_id] += count * 3 }
    reviews.each { |game_id, count| game_scores[game_id] += count * 4 }

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
