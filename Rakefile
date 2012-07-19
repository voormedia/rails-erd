# encoding: utf-8
require "bundler"
require "rake/testtask"
require "yard"

Bundler::GemHelper.install_tasks

Rake::TestTask.new do |test|
  test.test_files = FileList["test/**/*_test.rb"]
end

YARD::Rake::YardocTask.new do |yard|
  yard.files = ["lib/**/*.rb", "-", "LICENSE", "CHANGES.rdoc"]
end

task :default => :test
