class ApplicationMailer < ActionMailer::Base
  default from: ENV["EMAIL"] || "noreply@fiscalapi.com"
  layout "mailer"
end
