require "bundler"
require "rake/testtask"
require "yard"

Bundler::GemHelper.install_tasks

Rake::TestTask.new do |test|
  test.test_files = FileList["test/**/*_test.rb"]
end

YARD::Rake::YardocTask.new do |yard|
  yard.files = ["lib/**/*.rb", "-", "LICENSE", "CHANGES.md"]
end

desc "Generate diagrams for bundled examples"
task :examples do
  require File.expand_path("examples/generate", File.dirname(__FILE__))
end

task :default => :test
