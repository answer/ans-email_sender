# -*- coding: utf-8 -*-

require 'spec_helper'

class EmailQueue < ActiveRecord::Base
  include Ans::EmailSender::Model
end

module Ans::EmailSender

  describe Job do
    before do
      class JobTest
        include Job

        class << self
          attr_accessor :error, :after, :after_message
        end

        def validate!(email_queue)
          raise self.class.error if self.class.error
        end
        def after_deliver(email_queue)
          self.class.after_message = "#{self.class.after}: #{email_queue.id}" if self.class.after
        end
      end

      SystemSetting.delete_all
    end

    context "通常の場合" do
      let(:queue){
        q = EmailQueue.new
        q.from = "info@ans-web.co.jp"
        q.to = "to@ans-web.co.jp"
        q.subject = "題名"
        q.body = "本文"
        q.save
        q
      }
      before do
        queue
        JobTest.perform
        queue.reload
      end

      describe "queue.email_queue_publish_id" do
        subject{queue.email_queue_publish_id}
        it{should be_present}
      end
      describe "queue.sent_at" do
        subject{queue.sent_at}
        it{should be_present}
      end
    end

    context "処理済みのキュー" do
      let(:queue){
        q = EmailQueue.new
        q.from = "info@ans-web.co.jp"
        q.to = "to@ans-web.co.jp"
        q.subject = "題名"
        q.body = "本文"
        q.sent_at = Time.zone.parse("2011/01/01 9:00:00")
        q.email_queue_publish_id = 0
        q.save
        q
      }
      before do
        queue
        JobTest.perform
        queue.reload
      end

      describe "queue.email_queue_publish_id" do
        subject{queue.email_queue_publish_id}
        it{should be_present}
      end
      describe "queue.sent_at" do
        subject{queue.sent_at}
        it{should == Time.zone.parse("2011/01/01 9:00:00")}
      end
    end

    context "送信エラー" do
      let(:queue){
        q = EmailQueue.new
        q.from = "info@ans-web.co.jp"
        q.to = "to@ans-web.co.jp"
        q.subject = "題名"
        q.body = "本文"
        q.save
        q
      }

      before do
        class JobTest
          def mail(queue)
            raise "送信失敗"
          end
        end

        queue
        JobTest.perform
        queue.reload
      end

      describe "queue.email_queue_publish_id" do
        subject{queue.email_queue_publish_id}
        it{should be_present}
      end
      describe "queue.send_error" do
        subject{queue.send_error}
        it{should == "ERROR: 送信失敗"}
      end
    end

    context "送信エラー(カスタム)" do
      let(:queue){
        q = EmailQueue.new
        q.from = "info@ans-web.co.jp"
        q.to = "to@ans-web.co.jp"
        q.subject = "題名"
        q.body = "本文"
        q.save
        q
      }

      before do
        queue
        JobTest.error = "エラー"
        JobTest.perform
        queue.reload
      end

      describe "queue.email_queue_publish_id" do
        subject{queue.email_queue_publish_id}
        it{should be_present}
      end
      describe "queue.send_error" do
        subject{queue.send_error}
        it{should == "ERROR: エラー"}
      end
    end

    context "送信後処理" do
      let(:queue){
        q = EmailQueue.new
        q.from = "info@ans-web.co.jp"
        q.to = "to@ans-web.co.jp"
        q.subject = "題名"
        q.body = "本文"
        q.save
        q
      }

      before do
        queue
        JobTest.after = "後"
        JobTest.perform
        queue.reload
      end

      describe "queue.email_queue_publish_id" do
        subject{queue.email_queue_publish_id}
        it{should be_present}
      end
      describe "JobTest.after_message" do
        subject{JobTest.after_message}
        it{should == "後: #{queue.id}"}
      end
    end

    context "送信制限" do
      before do
        {
          email_send_limit_of_minute: 100,
          email_send_limit_of_hour: 150,
          email_send_limit_of_day: 200,
          email_send_limit_of_week: 250,
        }.each do |key,value|
          s = SystemSetting.new
          s.name = key
          s.value = value
          s.save
        end

        EmailQueue.connection.execute "".tap{|sql|
          sql << "insert into email_queues(created_at,updated_at) values"
          sql << [].tap{|values| new_count.times{values << "(now(),now())"}}.join(",")
        } if new_count > 0

        EmailQueue.connection.execute "".tap{|sql|
          sql << "insert into email_queues(email_queue_publish_id,created_at,updated_at,sent_at) values"
          sql << [].tap{|values| minute_count.times{values << "(0,now(),now(),now() - interval 1 minute + interval 1 second)"}}.join(",")
        } if minute_count > 0
        EmailQueue.connection.execute "".tap{|sql|
          sql << "insert into email_queues(email_queue_publish_id,created_at,updated_at,sent_at) values"
          sql << [].tap{|values| hour_count.times{values << "(0,now(),now(),now() - interval 1 hour + interval 1 second)"}}.join(",")
        } if hour_count > 0
        EmailQueue.connection.execute "".tap{|sql|
          sql << "insert into email_queues(email_queue_publish_id,created_at,updated_at,sent_at) values"
          sql << [].tap{|values| day_count.times{values << "(0,now(),now(),now() - interval 1 day + interval 1 second)"}}.join(",")
        } if day_count > 0
        EmailQueue.connection.execute "".tap{|sql|
          sql << "insert into email_queues(email_queue_publish_id,created_at,updated_at,sent_at) values"
          sql << [].tap{|values| week_count.times{values << "(0,now(),now(),now() - interval 1 week + interval 1 second)"}}.join(",")
        } if week_count > 0

        JobTest.perform
      end

      let(:new_count){200}

      context "一分間に 50 件送信済みの場合" do
        let(:minute_count){50}
        let(:hour_count){0}
        let(:day_count){0}
        let(:week_count){0}

        describe "送信済み数" do
          subject{EmailQueue.where("`email_queues`.`email_queue_publish_id` > 0").count}
          it{should == 50}
        end
        describe "未送信済み数" do
          subject{EmailQueue.where(email_queue_publish_id: nil).count}
          it{should == 150}
        end
      end

      context "一時間に 100 件送信済みの場合" do
        let(:minute_count){0}
        let(:hour_count){100}
        let(:day_count){0}
        let(:week_count){0}

        describe "送信済み数" do
          subject{EmailQueue.where("`email_queues`.`email_queue_publish_id` > 0").count}
          it{should == 50}
        end
        describe "未送信済み数" do
          subject{EmailQueue.where(email_queue_publish_id: nil).count}
          it{should == 150}
        end
      end

      context "一日に 150 件送信済みの場合" do
        let(:minute_count){0}
        let(:hour_count){0}
        let(:day_count){150}
        let(:week_count){0}

        describe "送信済み数" do
          subject{EmailQueue.where("`email_queues`.`email_queue_publish_id` > 0").count}
          it{should == 50}
        end
        describe "未送信済み数" do
          subject{EmailQueue.where(email_queue_publish_id: nil).count}
          it{should == 150}
        end
      end

      context "一週間に 200 件送信済みの場合" do
        let(:minute_count){0}
        let(:hour_count){0}
        let(:day_count){0}
        let(:week_count){200}

        describe "送信済み数" do
          subject{EmailQueue.where("`email_queues`.`email_queue_publish_id` > 0").count}
          it{should == 50}
        end
        describe "未送信済み数" do
          subject{EmailQueue.where(email_queue_publish_id: nil).count}
          it{should == 150}
        end
      end
    end
  end
end
