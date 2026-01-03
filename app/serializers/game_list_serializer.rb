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
end

