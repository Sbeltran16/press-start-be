# Script to auto-confirm all existing users
# Run this in Rails console: load 'lib/scripts/confirm_existing_users.rb'

puts "🔍 Finding unconfirmed users..."
unconfirmed_count = User.where(confirmed_at: nil).count
puts "Found #{unconfirmed_count} unconfirmed users"

if unconfirmed_count == 0
  puts "✅ All users are already confirmed!"
else
  confirmed = 0
  User.where(confirmed_at: nil).find_each do |user|
    user.update_column(:confirmed_at, Time.current)
    confirmed += 1
    puts "✓ Confirmed user: #{user.email} (#{user.username})"
  end
  
  puts "\n✅ Successfully confirmed #{confirmed} users!"
end

