# -*- encoding: utf-8 -*-
$LOAD_PATH.unshift File.expand_path("../lib", __FILE__)
require "rspec/core/version"

Gem::Specification.new do |s|
  s.name        = "rspec-core"
  #s.version     = RSpec::Core::Version::STRING
  s.version     = "2.10.0"
  s.platform    = Gem::Platform::RUBY
  s.license     = "MIT"
  s.authors     = ["Steven Baker", "David Chelimsky", "Chad Humphries"]
  s.email       = "roygunter@gmail.com"
  s.homepage    = "http://github.com/roy-gunter/rspec-core"
  s.summary     = "rspec-core-#{RSpec::Core::Version::STRING}"
  s.description = "BDD for Ruby. RSpec runner and example groups."

  s.rubyforge_project  = "rspec"

  s.files            = `git ls-files -- lib/*`.split("\n")
  s.files           += %w[README.md License.txt Changelog.md .yardopts .document]
  s.test_files       = `git ls-files -- {spec,features}/*`.split("\n")
  s.bindir           = 'exe'
  s.executables      = `git ls-files -- exe/*`.split("\n").map{ |f| File.basename(f) }
  s.rdoc_options     = ["--charset=UTF-8"]
  s.require_path     = "lib"

  s.add_development_dependency "rake",     "~> 0.9.2"
  s.add_development_dependency "cucumber", "~> 1.1.9"
  s.add_development_dependency "aruba",    "~> 0.4.11"

  s.add_development_dependency "ZenTest",  "4.6.2"
  s.add_development_dependency "nokogiri", "1.5.2"
  s.add_development_dependency "fakefs",   "0.4.0"
  s.add_development_dependency "syntax",   "1.0.0"

  s.add_development_dependency "mocha",    "~> 0.10.5"
  s.add_development_dependency "rr",       "~> 1.0.4"
  s.add_development_dependency "flexmock", "~> 0.9.0"
end
