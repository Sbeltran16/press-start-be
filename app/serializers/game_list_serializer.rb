class GameListSerializer
  include JSONAPI::Serializer
  attributes :id, :name, :description, :created_at, :updated_at

  attribute :games_count do |list|
    list.games_count
  end

  attribute :likes_count do |list|
    list.likes_count
  end

  attribute :liked_by_current_user do |list, params|
    current_user = params[:current_user]
    current_user ? list.liked_by?(current_user) : false
  end

  attribute :first_game_id do |list|
    list.first_game_id
  end

  attribute :user do |list|
    {
      id: list.user.id,
      username: list.user.username,
      profile_picture_url: list.user.profile_picture_url
    }
  end

  attribute :game_ids do |list|
    list.game_list_items.order(:position).pluck(:igdb_game_id)
  end

  # How many games from this list the current user has played
  attribute :games_completed_count do |list, params|
    current_user = params && params[:current_user]
    unless current_user
      0
    else
      game_ids = list.game_list_items.pluck(:igdb_game_id)
      if game_ids.empty?
        0
      else
        # game_plays.igdb_game_id is stored as string, so cast ids to strings
        GamePlay.where(user_id: current_user.id, igdb_game_id: game_ids.map(&:to_s)).count
      end
    end
  end

  # Percentage of games in the list the current user has played
  attribute :games_completed_percentage do |list, params|
    current_user = params && params[:current_user]
    unless current_user
      nil
    else
      total = list.games_count
      if total.zero?
        nil
      else
        completed = GamePlay.where(
          user_id: current_user.id,
          igdb_game_id: list.game_list_items.pluck(:igdb_game_id).map(&:to_s)
        ).count

        ((completed.to_f / total) * 100).round
      end
    end
  end
end

