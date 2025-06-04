class CreateFavoriteGames < ActiveRecord::Migration[7.1]
  def change
    create_table :favorite_games do |t|
      t.references :user, null: false, foreign_key: true
      t.bigint :igdb_game_id
      t.integer :position

      t.timestamps
    end
  end
end
