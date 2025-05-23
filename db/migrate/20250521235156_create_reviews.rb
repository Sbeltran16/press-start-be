class CreateReviews < ActiveRecord::Migration[7.1]
  def change
    create_table :reviews do |t|
      t.references :user, null: false, foreign_key: true
      t.string :igdb_game_id
      t.float :rating
      t.text :comment

      t.timestamps
    end

    add_index :reviews, [:user_id, :igdb_game_id], unique: true
  end
end
