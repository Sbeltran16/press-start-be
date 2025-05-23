class CreateReviewComments < ActiveRecord::Migration[7.1]
  def change
    create_table :review_comments do |t|
      t.references :user, null: false, foreign_key: true
      t.references :review, null: false, foreign_key: true
      t.text :content, null: false

      t.timestamps
    end
  end
end
