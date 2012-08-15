require "ans-email_sender/version"

module Ans
  module EmailSender
    autoload :Job, "ans-email_sender/job"
    autoload :Mailer, "ans-email_sender/mailer"
  end
end
