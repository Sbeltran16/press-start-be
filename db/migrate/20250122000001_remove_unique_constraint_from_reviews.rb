class RemoveUniqueConstraintFromReviews < ActiveRecord::Migration[7.1]
  def change
    remove_index :reviews, name: "index_reviews_on_user_id_and_igdb_game_id"
    add_index :reviews, [:user_id, :igdb_game_id]
  end
end
