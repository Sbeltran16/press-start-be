# Simple script to delete all users - no confirmation required
# Run this in Rails console: load 'lib/scripts/delete_all_users_simple.rb'

puts "🗑️  Deleting all users and associated records..."

user_count = User.count
puts "Found #{user_count} users to delete"

# Delete in correct order to avoid foreign key violations
ActiveRecord::Base.transaction do
  ReviewComment.delete_all
  ReviewLike.delete_all
  Review.delete_all
  Rating.delete_all
  ListLike.delete_all
  GameListItem.delete_all
  GameList.delete_all
  Follow.delete_all
  BacklogGame.delete_all
  FavoriteGame.delete_all
  GamePlay.delete_all
  GameLike.delete_all
  GameView.delete_all
  User.delete_all
end

puts "✅ Successfully deleted all users!"
puts "   Total users deleted: #{user_count}"

