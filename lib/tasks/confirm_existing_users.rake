namespace :users do
  desc "Auto-confirm all existing users who haven't confirmed their email"
  task confirm_all: :environment do
    unconfirmed_count = User.where(confirmed_at: nil).count
    puts "Found #{unconfirmed_count} unconfirmed users"
    
    if unconfirmed_count == 0
      puts "✅ All users are already confirmed!"
      next
    end
    
    confirmed = 0
    User.where(confirmed_at: nil).find_each do |user|
      user.update_column(:confirmed_at, Time.current)
      confirmed += 1
      puts "✓ Confirmed user: #{user.email} (#{user.username})"
    end
    
    puts "\n✅ Successfully confirmed #{confirmed} users!"
  end
end

