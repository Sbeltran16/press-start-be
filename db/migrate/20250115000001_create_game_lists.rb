class CreateGameLists < ActiveRecord::Migration[7.1]
  def change
    create_table :game_lists do |t|
      t.references :user, null: false, foreign_key: true
      t.string :name, null: false
      t.text :description

      t.timestamps
    end

    add_index :game_lists, [:user_id, :name], unique: true
  end
end

