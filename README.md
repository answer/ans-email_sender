# Ans::EmailSender

メールキューを処理する job を提供する

## Installation

Add this line to your application's Gemfile:

    gem 'ans-email_sender'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install ans-email_sender

## Usage

    # model
    class EmailQueue < ActiveRecord::Base
      include Ans::EmailSender::Model
    end

    # job
    class EmailSender
      include Ans::EmailSender::Job
      @queue = :mail

      def error(e,email_queue)
        # 例外によりメールが送信できなかった場合にコールされる
        # (ログの記録、エラー通知メールの送信、等)
      end
    end

    # resque scheduler file
    EmailSender:
      description: "メールキューを処理する"
      cron: "*/1 * * * *"

## 前提

EmailQueue は以下の属性を含む

* `priority` : `integer` : 優先度(小さいほうが優先)
* `to` : `string` : 送信先
* `from` : `string` : 送信元
* `subject` : `string` : 題名
* `body` : `text` : 本文
* `email_queue_publish_id` : `integer` : publishable で使用される ID
* `sent_at` : `datetime` : 送信時刻
* `send_error` : `string` : 送信エラー
* `message_id` : `string` : 送信したメールの Message-ID

SystemSetting は以下の属性を含む

* `name` : 参照名
* `value` : 値

## 機能

job クラスによって、メールの送信処理を行う

メールの送信は Ans::EmailSender::Mailer によって行われる

Ans::EmailSender::Mailer は ApplicationMailer 、もし存在しない場合は ActionMailer::Base を継承する

メールキューの取得には制限を設けることが出来る

## 設定

SystemSetting に以下の設定を行うことで、メールキューの取得に制限をかけることが出来る

* `email_send_limit_of_minute` : 一分間の送信制限
* `email_send_limit_of_hour` : 一時間の送信制限
* `email_send_limit_of_day` : 一日の送信制限
* `email_send_limit_of_week` : 一週間の送信制限

## オーバーライド可能なメソッド

    # model
    class EmailQueue
      include Ans::EmailSender::Model

      private

      def send_config
        # limit_of(type) メソッドが定義されたオブジェクトを返す
        # type には minute, hour, day, week が渡される
        @send_config ||= Ans::EmailSender::Config.new
      end
    end

    # job
    class EmailSender
      include Ans::EmailSender::Job
      @queue = :mail

      private

      def validate!(email_queue)
        # 例外を投げて送信をキャンセルする
        # メッセージは email_queue の send_error に保存される
        #raise "メールアドレスが不正です" if EmailAddress.ban(email_queue.to).count > 0
      end
      def after_deliver(email_queue)
        # 送信後の処理を行う
      end

      def mail(email_queue)
        # メールを送信するメールオブジェクトを返す
        Ans::EmailAddress::Mailer.queue(email_queue)
      end
    end

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
