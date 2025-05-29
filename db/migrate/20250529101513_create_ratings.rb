class CreateRatings < ActiveRecord::Migration[7.1]
  def change
    create_table :ratings do |t|
      t.references :user, null: false, foreign_key: true
      t.string :igdb_game_id
      t.float :rating

      t.timestamps
    end
  end
end
