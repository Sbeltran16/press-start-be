class CreateGameViews < ActiveRecord::Migration[7.1]
  def change
    create_table :game_views do |t|
      t.references :user, null: false, foreign_key: true
      t.integer :igdb_game_id

      t.timestamps
    end
  end
end
