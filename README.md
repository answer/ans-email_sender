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

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
