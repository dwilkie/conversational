# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "conversational/version"

Gem::Specification.new do |s|
  s.name        = "conversational"
  s.version     = Conversational::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["David Wilkie"]
  s.email       = ["dwilkie@gmail.com"]
  s.homepage    = ""
  s.summary     = %q{Have topic based conversations}
  s.description = %q{Allows you to instansiate conversations based on keywords}

  s.rubyforge_project = "conversational"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_dependency("activesupport")
  s.add_dependency("i18n")

  s.add_development_dependency("rspec")
end

