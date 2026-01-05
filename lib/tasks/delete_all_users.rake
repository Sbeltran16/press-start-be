namespace :users do
  desc "Delete all users and their associated records (for production cleanup)"
  task delete_all: :environment do
    puts "⚠️  WARNING: This will delete ALL users and their associated data!"
    puts "This includes: reviews, ratings, comments, likes, lists, follows, etc."
    puts ""
    print "Type 'DELETE ALL USERS' to confirm: "
    confirmation = STDIN.gets.chomp
    
    unless confirmation == 'DELETE ALL USERS'
      puts "❌ Deletion cancelled."
      exit
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
  end
end

