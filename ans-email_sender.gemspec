# -*- encoding: utf-8 -*-
require File.expand_path('../lib/ans-email_sender/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["sakai shunsuke"]
  gem.email         = ["sakai@ans-web.co.jp"]
  gem.description   = %q{メールキューを処理する job を提供する}
  gem.summary       = %q{メールキューを処理する}
  gem.homepage      = "https://github.com/answer/ans-email_sender"

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "ans-email_sender"
  gem.require_paths = ["lib"]
  gem.version       = Ans::EmailSender::VERSION

  gem.add_development_dependency "shoulda-matchers"
  gem.add_development_dependency "ans-matchers"

  gem.add_runtime_dependency "ans-publishable", "~> 1.0", ">= 1.0.6"
end
