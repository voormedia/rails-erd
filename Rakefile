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

  spec.add_runtime_dependency "activerecord", "~> 3.0.0"
  spec.add_runtime_dependency "activesupport", "~> 3.0"
  spec.add_runtime_dependency "ruby-graphviz", "~> 0.9.17"
  spec.add_development_dependency "sqlite3-ruby"
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
  require "rubygems"
  require "bundler"
  Bundler.require
  require "rails_erd/diagram/graphviz"

  %w{gemcutter typo}.each do |domain|
    puts "Generating ERD for #{domain.capitalize}..."
    begin
      # Load database schema.
      ActiveRecord::Base.establish_connection :adapter => "sqlite3", :database => ":memory:"
      ActiveRecord::Migration.suppress_messages do
        require File.expand_path("examples/#{domain}/schema.rb", File.dirname(__FILE__))
      end
      
      # Load domain models for this example.
      Dir["examples/#{domain}/models/**/*.rb"].each do |model|
        require File.expand_path(model, File.dirname(__FILE__))
      end

      # Generate ERD for this example.
      file_name = File.expand_path("examples/#{domain}.pdf", File.dirname(__FILE__))
      RailsERD::Diagram::Graphviz.create(:file_name => file_name)
    ensure
      # Completely remove all loaded Active Record models.
      ActiveRecord::Base.descendants.each do |model|
        Object.send :remove_const, model.name.to_sym
      end
      ActiveRecord::Base.direct_descendants.clear
      Arel::Relation.send :class_variable_set, :@@connection_tables_primary_keys, {}
      ActiveSupport::Dependencies::Reference.clear!
    end
  end
end
