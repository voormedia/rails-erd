# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "rails_erd/version"

Gem::Specification.new do |s|
  s.name        = "rails-erd"
  s.version     = RailsERD::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Rolf Timmermans"]
  s.email       = ["r.timmermans@voormedia.com"]
  s.homepage    = "https://github.com/voormedia/rails-erd"
  s.summary     = %q{Entity-relationship diagram for your Rails models.}
  s.description = %q{Automatically generate an entity-relationship diagram (ERD) for your Rails models.}

  s.rubyforge_project = "rails-erd"

  s.add_runtime_dependency "activerecord", [">= 3.0"]
  s.add_runtime_dependency "activesupport", [">= 3.0"]
  s.add_runtime_dependency "ruby-graphviz", ["~> 1.0.4"]
  s.add_runtime_dependency "choice", ["~> 0.1.6"]

  s.files         = `git ls-files -- {bin,lib,test}/* CHANGES.rdoc LICENSE Rakefile README.md`.split("\n")
  s.test_files    = `git ls-files -- test/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
end
