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

  s.required_ruby_version = '>= 1.9.3'

  s.add_runtime_dependency "activerecord", ">= 3.2"
  s.add_runtime_dependency "activesupport", ">= 3.2"
  s.add_runtime_dependency "ruby-graphviz", "~> 1.2"
  s.add_runtime_dependency "choice", "~> 0.2.0"

  s.files         = `git ls-files -- {bin,lib,test}/* CHANGES.rdoc LICENSE Rakefile README.md`.split("\n")
  s.test_files    = `git ls-files -- test/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
end
