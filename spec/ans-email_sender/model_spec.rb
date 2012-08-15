# -*- coding: utf-8 -*-

require 'spec_helper'
require "shoulda-matchers"
require "ans-matchers"

describe EmailQueue do
  before do
    class EmailQueue
      include Ans::EmailSender::Model
    end
  end

  describe "スコープ" do
    subject{EmailQueue}

    describe ".publishable" do
      before do
        stub(EmailQueue).send_limit{send_limit}
      end
      let(:paranoid){"WHERE (`email_queues`.`deleted_at` IS NULL)" if EmailQueue.paranoid?}

      context "send_limit が数値を返した場合" do
        let(:send_limit){100}
        it{should have_executable_scope(:publishable).by_sql(<<-__SQL)}
          SELECT  `email_queues`.* FROM `email_queues`
          #{paranoid}
          ORDER BY priority, id
          LIMIT 100
        __SQL
      end

      context "send_limit が負の数を返した場合" do
        let(:send_limit){-1}
        it{should have_executable_scope(:publishable).by_sql(<<-__SQL)}
          SELECT  `email_queues`.* FROM `email_queues`
          #{paranoid}
          ORDER BY priority, id
          LIMIT 0
        __SQL
      end

      context "send_limit が nil を返した場合" do
        let(:send_limit){nil}
        it{should have_executable_scope(:publishable).by_sql(<<-__SQL)}
          SELECT  `email_queues`.* FROM `email_queues`
          #{paranoid}
          ORDER BY priority, id
        __SQL
      end

    end

    describe ".send_while_a(type)" do
      let(:paranoid){"(`email_queues`.`deleted_at` IS NULL) AND" if EmailQueue.paranoid?}
      context "1分間" do
        it{should have_executable_scope(:send_while_a).params("minute").by_sql(<<-__SQL)}
          SELECT `email_queues`.* FROM `email_queues`
          WHERE #{paranoid} (`email_queues`.`sent_at` > now() - interval 1 minute)
        __SQL
      end
      context "1時間" do
        it{should have_executable_scope(:send_while_a).params("hour").by_sql(<<-__SQL)}
          SELECT `email_queues`.* FROM `email_queues`
          WHERE #{paranoid} (`email_queues`.`sent_at` > now() - interval 1 hour)
        __SQL
      end
      context "1日" do
        it{should have_executable_scope(:send_while_a).params("day").by_sql(<<-__SQL)}
          SELECT `email_queues`.* FROM `email_queues`
          WHERE #{paranoid} (`email_queues`.`sent_at` > now() - interval 1 day)
        __SQL
      end
      context "1週間" do
        it{should have_executable_scope(:send_while_a).params("week").by_sql(<<-__SQL)}
          SELECT `email_queues`.* FROM `email_queues`
          WHERE #{paranoid} (`email_queues`.`sent_at` > now() - interval 1 week)
        __SQL
      end

      context "不明なタイプ" do
        it "は、 ArgumentError を発生する" do
          lambda{EmailQueue.send_while_a "unknown"}.should raise_error ArgumentError, %Q{type must be in ["minute", "hour", "day", "week"]}
        end
      end

    end

  end

  describe "クラスメソッド" do

    describe "send_limit" do
      subject{EmailQueue.send_limit}

      before do
        config = Object.new
        limits.each do |type,limit|
          stub(config).limit_of("#{type}"){limit.to_s}
        end
        stub(EmailQueue).send_config{config}

        counts.each do |type,count|
          stub(EmailQueue).send_while_a(type.to_s).stub!.count{count}
        end
      end

      context "送信制限が全部設定されている場合" do
        let(:limits){{ minute: 100, hour: 200, day: 300, week: 400 }}

        context "minute の制限が一番少ない場合" do
          let(:counts){{ minute: 50, hour: 0, day: 0, week: 0 }}
          it{should == 50}
        end
        context "hour の制限が一番少ない場合", min_count: :hour do
          let(:counts){{ minute: 0, hour: 160, day: 0, week: 0 }}
          it{should == 40}
        end
        context "day の制限が一番少ない場合", min_count: :day do
          let(:counts){{ minute: 0, hour: 0, day: 270, week: 0 }}
          it{should == 30}
        end
        context "week の制限が一番少ない場合", min_count: :week do
          let(:counts){{ minute: 0, hour: 0, day: 0, week: 380 }}
          it{should == 20}
        end
      end

      context "分の送信制限が設定されていない場合" do
        let(:limits){{ minute: "", hour: 200, day: 300, week: 400 }}

        context "minute の制限が一番少ない場合", min_count: :minute do
          let(:counts){{ minute: 50, hour: 0, day: 0, week: 0 }}
          it{should == 200}
        end
        context "hour の制限が一番少ない場合", min_count: :hour do
          let(:counts){{ minute: 0, hour: 160, day: 0, week: 0 }}
          it{should == 40}
        end
        context "day の制限が一番少ない場合", min_count: :day do
          let(:counts){{ minute: 0, hour: 0, day: 270, week: 0 }}
          it{should == 30}
        end
        context "week の制限が一番少ない場合", min_count: :week do
          let(:counts){{ minute: 0, hour: 0, day: 0, week: 380 }}
          it{should == 20}
        end
      end

      context "時間の送信制限が設定されていない場合" do
        let(:limits){{ minute: 100, hour: "", day: 300, week: 400 }}

        context "minute の制限が一番少ない場合", min_count: :minute do
          let(:counts){{ minute: 50, hour: 0, day: 0, week: 0 }}
          it{should == 50}
        end
        context "hour の制限が一番少ない場合", min_count: :hour do
          let(:counts){{ minute: 0, hour: 160, day: 0, week: 0 }}
          it{should == 100}
        end
        context "day の制限が一番少ない場合", min_count: :day do
          let(:counts){{ minute: 0, hour: 0, day: 270, week: 0 }}
          it{should == 30}
        end
        context "week の制限が一番少ない場合", min_count: :week do
          let(:counts){{ minute: 0, hour: 0, day: 0, week: 380 }}
          it{should == 20}
        end
      end

      context "日の送信制限が設定されていない場合" do
        let(:limits){{ minute: 100, hour: 200, day: "", week: 400 }}

        context "minute の制限が一番少ない場合", min_count: :minute do
          let(:counts){{ minute: 50, hour: 0, day: 0, week: 0 }}
          it{should == 50}
        end
        context "hour の制限が一番少ない場合", min_count: :hour do
          let(:counts){{ minute: 0, hour: 160, day: 0, week: 0 }}
          it{should == 40}
        end
        context "day の制限が一番少ない場合", min_count: :day do
          let(:counts){{ minute: 0, hour: 0, day: 270, week: 0 }}
          it{should == 100}
        end
        context "week の制限が一番少ない場合", min_count: :week do
          let(:counts){{ minute: 0, hour: 0, day: 0, week: 380 }}
          it{should == 20}
        end
      end

      context "週の送信制限が設定されていない場合" do
        let(:limits){{ minute: 100, hour: 200, day: 300, week: "" }}

        context "minute の制限が一番少ない場合", min_count: :minute do
          let(:counts){{ minute: 50, hour: 0, day: 0, week: 0 }}
          it{should == 50}
        end
        context "hour の制限が一番少ない場合", min_count: :hour do
          let(:counts){{ minute: 0, hour: 160, day: 0, week: 0 }}
          it{should == 40}
        end
        context "day の制限が一番少ない場合", min_count: :day do
          let(:counts){{ minute: 0, hour: 0, day: 270, week: 0 }}
          it{should == 30}
        end
        context "week の制限が一番少ない場合", min_count: :week do
          let(:counts){{ minute: 0, hour: 0, day: 0, week: 380 }}
          it{should == 100}
        end
      end

      context "送信制限が全部設定されていない場合" do
        let(:limits){{ minute: "", hour: "", day: "", week: "" }}
        let(:counts){{ minute: 0, hour: 0, day: 0, week: 0 }}
        it{should be_nil}
      end

    end
  end
end
