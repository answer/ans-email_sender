# -*- coding: utf-8 -*-

module Ans::EmailSender
  begin
    class Mailer < ApplicationMailer; end
  rescue NameError => ignore_name_error
    # ApplicationMailer が定義されていない場合は ActionMailer::Base を継承する
    class Mailer < ActionMailer::Base; end
  end

  class Mailer
    def queue(queue)
      mail to: queue.to, from: queue.from, subject: queue.subject, body: queue.body
    end
  end
end
