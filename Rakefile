# encoding: utf-8
require "jeweler"
require "rake/testtask"

Jeweler::Tasks.new do |spec|
  spec.name = "rails-erd"
  spec.rubyforge_project = "rails-erd"
  spec.summary = "Entity-relationship diagram for your Rails models."
  spec.description = "Automatically generate an entity-relationship diagram (ERD) for your Rails models."

  spec.authors = ["Rolf Timmermans"]
  spec.email = "r.timmermans@voormedia.com"
  spec.homepage = "http://rails-erd.rubyforge.org/"

  spec.add_runtime_dependency "activerecord", "~> 3.0"
  spec.add_runtime_dependency "activesupport", "~> 3.0"
  spec.add_runtime_dependency "ruby-graphviz", "~> 0.9.18"
  spec.add_development_dependency "sqlite3-ruby"
  
  # Don't bundle examples or website in gem.
  excluded = Dir["{examples,site}/**/*"]
  spec.files -= excluded
  spec.test_files -= excluded
end

Jeweler::GemcutterTasks.new

Jeweler::RubyforgeTasks.new do |rubyforge|
  rubyforge.doc_task = "rdoc"
  rubyforge.remote_doc_path = "doc"
end

Rake::TestTask.new do |test|
  test.pattern = "test/unit/**/*_test.rb"
end

task :default => :test

begin
  require "hanna/rdoctask"
  Rake::RDocTask.new do |rdoc|
    rdoc.rdoc_files = Dir["[A-Z][A-Z]*"] + Dir["lib/**/*.rb"]
    rdoc.title = "Rails ERD – Entity-Relationship Diagrams for Rails"
    rdoc.rdoc_dir = "rdoc"
  end
rescue LoadError
end

desc "Generate diagrams for bundled examples"
task :examples do
  require File.expand_path("examples/generate", File.dirname(__FILE__))
end
