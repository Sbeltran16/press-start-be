class AddFavoriteGameIdsToUsers < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :favorite_game_ids, :integer, array: true, default: []
  end
end
