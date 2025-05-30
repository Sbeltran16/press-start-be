class CreateGamePlays < ActiveRecord::Migration[7.1]
  def change
    create_table :game_plays do |t|
      t.references :user, null: false, foreign_key: true
      t.string :igdb_game_id

      t.timestamps
    end
    add_index :game_plays, [:user_id, :igdb_game_id], unique: true
  end
end
