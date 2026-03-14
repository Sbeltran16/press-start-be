# frozen_string_literal: true

class CreateGamesCache < ActiveRecord::Migration[7.1]
  def change
    create_table :games do |t|
      t.bigint :igdb_id, null: false, index: { unique: true }
      t.string :name, null: false
      t.string :slug, index: true
      t.jsonb :data, null: false, default: {}

      t.timestamps
    end

    add_index :games, :name
  end
end
