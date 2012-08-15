# -*- coding: utf-8 -*-

require "spec_helper"

module Ans::EmailSender
  describe Mailer do
    subject{Mailer.send :new}
    if defined? ApplicationMailer
      it{should be_a ApplicationMailer}
    else
      it{should be_a ActionMailer::Base}
    end

    it{should be_respond_to :queue}
  end
end
