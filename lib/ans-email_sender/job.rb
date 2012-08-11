# -*- coding: utf-8 -*-

module Ans::EmailSender
  class Job
    class CheckFault < StandardError; end

    @queue = :mail

    def self.perform
      EmailQueue.publish do |queue|
        new(queue).deliver
      end
    end

    def initialize(queue)
      @queue = queue
    end

    def deliver
      check_email_address
      exec_deliver

    rescue CheckFault => e
      @error = e.message

    rescue => all_deliver_errors
      @error = "メール送信エラー"

    ensure
      save_send_status
    end

    private

    def check_email_address
      # メールアドレスが登録されていなければ何もしない
      return unless email_address = @queue.user_email_address

      raise CheckFault, "メールアドレスがブラックに設定されています" if email_address.is_black
      raise CheckFault, "メールアドレスがエラーに設定されています" if email_address.is_error
    end

    def exec_deliver
      Member::Mailer.queue(@queue).deliver
    end

    def save_send_status
      unless @error
        send_ok
      else
        send_error @error
      end
    end
    def send_ok
      @queue.update_attributes send_datetime: Time.now
    end
    def send_error(message)
      @queue.update_attributes send_memo: message
    end

  end
end
