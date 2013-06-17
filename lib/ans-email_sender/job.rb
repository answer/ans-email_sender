# -*- coding: utf-8 -*-

module Ans::EmailSender
  module Job
    def self.included(m)
      m.send :extend, ClassMethods
    end

    module ClassMethods
      def perform
        EmailQueue.publish do |email_queue|
          new.deliver(email_queue)
        end
      end
    end

    def deliver(email_queue)
      validate! email_queue
      email_queue.message_id = mail(email_queue).deliver.message_id

    rescue => e
      email_queue.send_error = "ERROR: #{e.message}"
      error e, email_queue
    else
      email_queue.sent_at = Time.now
    ensure
      email_queue.save
      after_deliver email_queue
    end

    private

    def validate!(email_queue)
    end
    def after_deliver(email_queue)
    end

    def mail(email_queue)
      Ans::EmailSender::Mailer.queue(email_queue)
    end

    def error(e,email_queue)
    end

  end
end
