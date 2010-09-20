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

  spec.add_runtime_dependency "activesupport", "~> 3.0.0"
  spec.add_runtime_dependency "ruby-graphviz", "~> 0.9.17"
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
rescue => e
  puts e.message
end
