class AddUniqueIndexToRatings < ActiveRecord::Migration[7.1]
  def change
    add_index :ratings, [:user_id, :igdb_game_id], unique: true
  end
end
