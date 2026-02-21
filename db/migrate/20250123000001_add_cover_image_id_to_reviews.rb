class AddCoverImageIdToReviews < ActiveRecord::Migration[7.1]
  def change
    add_column :reviews, :cover_image_id, :string
  end
end
