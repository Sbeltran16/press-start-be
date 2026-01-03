class CreateGameListItems < ActiveRecord::Migration[7.1]
  def change
    create_table :game_list_items do |t|
      t.references :game_list, null: false, foreign_key: true
      t.bigint :igdb_game_id, null: false
      t.integer :position, default: 0

      t.timestamps
    end

    add_index :game_list_items, [:game_list_id, :igdb_game_id], unique: true
    add_index :game_list_items, [:game_list_id, :position]
  end
end

