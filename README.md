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

### model

* `send_config` : 設定オブジェクトを返す

#### `send_config`

`limit_of(type)` メソッドが定義されたオブジェクトを返す

type には minute, hour, day, week が渡される

デフォルトは、 SystemSetting から `email_send_limit_of_minute` 等の値を読むクラスが使用される

### job

* `validate!(email_queue)` : キューの中身を検証する
* `after_deliver(email_queue)` : 送信処理の後処理を行う
* `mail(email_queue)` : メールを送信する mail クラスを返す

#### `validate!(email_queue)`

処理予定の `email_queue` の検証を行う

送信をキャンセルする場合、例外を raise する

デフォルトは何もしない

#### `after_deliver(email_queue)`

処理を行った `email_queue` の後処理を行う

デフォルトは何もしない

#### `mail(email_queue)`

メールを送信するメールオブジェクトを返す

デフォルトは `Ans::EmailSender::Mailer.queue(email_queue)`

`Ans::EmailSender::Mailer` は `ApplicationMailer` が定義されていればそれを、されていなければ `ActionMailer::Base` を継承する

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
