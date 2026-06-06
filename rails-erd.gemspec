$:.push File.expand_path("../lib", __FILE__)
require "rails_erd/version"

Gem::Specification.new do |s|
  s.name        = "rails-erd"
  s.version     = RailsERD::VERSION
  s.authors     = ["Rolf Timmermans", "Kerri Miller"]
  s.email       = ["r.timmermans@voormedia.com", "kerrizor@kerrizor.com"]
  s.homepage    = "https://github.com/voormedia/rails-erd"
  s.summary     = "Entity-relationship diagram for your Rails models."
  s.description = "Automatically generate an entity-relationship diagram (ERD) for your Rails models."
  s.license     = "MIT"

  s.required_ruby_version = '>= 3.1'

  s.add_runtime_dependency "activerecord", ">= 7.0"
  s.add_runtime_dependency "activesupport", ">= 7.0"
  s.add_runtime_dependency "ruby-graphviz", "~> 1.2"
  s.add_runtime_dependency "choice", "~> 0.2.0"
  s.add_runtime_dependency "ostruct" # Required as of Ruby 3.5 (no longer in stdlib)

  s.add_development_dependency "pry"
  s.add_development_dependency "pry-nav"

  s.files         = `git ls-files -- {bin,lib,test}/* CHANGES.rdoc LICENSE Rakefile README.md`.split("\n")
  s.test_files    = `git ls-files -- test/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
end
