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
    rdoc.rdoc_files = %w{CHANGES.rdoc LICENSE} + Dir["lib/**/*.rb"]
    rdoc.title = "Rails ERD – API Documentation"
    rdoc.rdoc_dir = "rdoc"
    rdoc.main = "RailsERD"
  end
rescue LoadError
end

desc "Generate diagrams for bundled examples"
task :examples do
  require File.expand_path("examples/generate", File.dirname(__FILE__))
end

namespace :examples do
  task :sfdp do
    require File.expand_path("examples/sfdp", File.dirname(__FILE__))
  end
end
