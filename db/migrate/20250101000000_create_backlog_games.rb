class CreateBacklogGames < ActiveRecord::Migration[7.1]
  # Migration timestamp updated to be after latest migration
  def change
    create_table :backlog_games do |t|
      t.references :user, null: false, foreign_key: true
      t.bigint :igdb_game_id

      t.timestamps
    end

    add_index :backlog_games, [:user_id, :igdb_game_id], unique: true
  end
end

