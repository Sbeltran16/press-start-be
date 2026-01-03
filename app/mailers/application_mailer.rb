class ApplicationMailer < ActionMailer::Base
  default from: ENV['MAILER_FROM'] || 'noreply@pressstart.gg'
  layout 'mailer'
end
