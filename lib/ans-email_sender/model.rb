# -*- coding: utf-8 -*-

require "ans-publishable"

module Ans::EmailSender
  module Model
    def self.included(m)
      m.class_eval do
        scope :publishable, lambda{|opts={}|
          limit = send_limit

          result = order(:priority, :id)
          result = result.limit([limit,0].max) if limit
          result
        }
        scope :send_while_a, lambda{|type|
          raise ArgumentError, "type must be in #{send_limit_types}" unless send_limit_types.include? type
          where("`email_queues`.`sent_at` > now() - interval 1 #{type}")
        }
      end

      m.send :include, Ans::Publishable
      m.send :extend,  ClassMethods
    end

    module ClassMethods

      def send_limit
        limits = send_limit_types.map{|type| [type,send_limit_of(type)]}.select{|type,limit| limit}
        return unless limits
        limits.map{|type,limit| limit - send_while_a(type).count}.min
      end

      private

      def send_limit_types
        ["minute","hour","day","week"]
      end

      def send_limit_of(type)
        limit = send_config.limit_of type
        limit.present? ? limit.to_i : nil
      end
      def send_config
        @send_config = Config.new
      end

    end
  end
end
