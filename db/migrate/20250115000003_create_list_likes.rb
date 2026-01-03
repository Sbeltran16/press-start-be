class CreateListLikes < ActiveRecord::Migration[7.1]
  def change
    create_table :list_likes do |t|
      t.references :user, null: false, foreign_key: true
      t.references :game_list, null: false, foreign_key: true

      t.timestamps
    end

    add_index :list_likes, [:user_id, :game_list_id], unique: true
  end
end

