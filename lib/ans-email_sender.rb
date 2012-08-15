require "ans-email_sender/version"

module Ans
  module EmailSender
    autoload :Job,    "ans-email_sender/job"
    autoload :Mailer, "ans-email_sender/mailer"
    autoload :Model,  "ans-email_sender/model"
    autoload :Config, "ans-email_sender/config"
  end
end
