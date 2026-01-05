class ApplicationMailer < ActionMailer::Base
  # Set default from with display name to hide personal email
  # Format: "Display Name <email@address.com>"
  from_email = ENV['SMTP_USERNAME'] || ENV['MAILER_FROM'] || 'noreply@pressstart.gg'
  display_name = ENV['MAILER_DISPLAY_NAME'] || 'Press Start'
  default from: "#{display_name} <#{from_email}>"
  default reply_to: ENV['MAILER_REPLY_TO'] || from_email
  layout 'mailer'
end
