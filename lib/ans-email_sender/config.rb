# -*- coding: utf-8 -*-

module Ans::EmailSender
  class Config
    def limit_of(type)
      @config ||= {}
      @config[type.to_sym] ||= SystemSetting.find_by_name("email_send_limit_of_#{type}").try(:value)
    end
  end
end
