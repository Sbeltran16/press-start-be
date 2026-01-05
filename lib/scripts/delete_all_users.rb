# Script to delete all users and their associated records
# Run this in Rails console: load 'lib/scripts/delete_all_users.rb'
# Or call: delete_all_users(confirm: true)

def delete_all_users(confirm: false)
  puts "⚠️  WARNING: This will delete ALL users and their associated data!"
  puts "This includes: reviews, ratings, comments, likes, lists, follows, etc."
  puts ""
  
  if confirm
    print "Type 'DELETE ALL USERS' to confirm: "
    begin
      confirmation = STDIN.gets&.chomp
      unless confirmation == 'DELETE ALL USERS'
        puts "❌ Deletion cancelled."
        return false
      end
    rescue => e
      puts "⚠️  Could not read confirmation (this is normal in some environments)"
      puts "   Proceeding without confirmation..."
    end
  else
    puts "⚠️  Running without confirmation (confirm: false)"
    puts "   To require confirmation, call: delete_all_users(confirm: true)"
  end

puts "\n🗑️  Starting deletion process..."

# Count records before deletion
user_count = User.count
puts "Found #{user_count} users to delete"

# Delete in correct order to avoid foreign key violations
ActiveRecord::Base.transaction do
  puts "\n1. Deleting review comments..."
  ReviewComment.delete_all
  puts "   ✓ Deleted all review comments"
  
  puts "\n2. Deleting review likes..."
  ReviewLike.delete_all
  puts "   ✓ Deleted all review likes"
  
  puts "\n3. Deleting reviews..."
  Review.delete_all
  puts "   ✓ Deleted all reviews"
  
  puts "\n4. Deleting ratings..."
  Rating.delete_all
  puts "   ✓ Deleted all ratings"
  
  puts "\n5. Deleting list likes..."
  ListLike.delete_all
  puts "   ✓ Deleted all list likes"
  
  puts "\n6. Deleting game list items..."
  GameListItem.delete_all
  puts "   ✓ Deleted all game list items"
  
  puts "\n7. Deleting game lists..."
  GameList.delete_all
  puts "   ✓ Deleted all game lists"
  
  puts "\n8. Deleting follows..."
  Follow.delete_all
  puts "   ✓ Deleted all follows"
  
  puts "\n9. Deleting backlog games..."
  BacklogGame.delete_all
  puts "   ✓ Deleted all backlog games"
  
  puts "\n10. Deleting favorite games..."
  FavoriteGame.delete_all
  puts "   ✓ Deleted all favorite games"
  
  puts "\n11. Deleting game plays..."
  GamePlay.delete_all
  puts "   ✓ Deleted all game plays"
  
  puts "\n12. Deleting game likes..."
  GameLike.delete_all
  puts "   ✓ Deleted all game likes"
  
  puts "\n13. Deleting game views..."
  GameView.delete_all
  puts "   ✓ Deleted all game views"
  
  puts "\n14. Deleting all users..."
  User.delete_all
  puts "   ✓ Deleted all users"
end

puts "\n✅ Successfully deleted all users and associated records!"
puts "   Total users deleted: #{user_count}"
return true
end

# Auto-run only if explicitly called, not during server startup
if defined?(Rails::Console) && !defined?(Rails::Server)
  # Only auto-run in console, not during server startup
  puts "\n💡 To delete all users, run: delete_all_users"
  puts "   Or with confirmation: delete_all_users(confirm: true)"
end

