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
  spec.add_runtime_dependency "ruby-graphviz", "~> 0.9.17"
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
  require "rubygems"
  require "bundler"
  Bundler.require
  require "rails_erd/diagram/graphviz"

  Dir["examples/*/*"].each do |path|
    name = File.basename(path)
    print "==> Generating ERD for #{name.capitalize}... "
    begin
      # Load database schema.
      ActiveRecord::Base.establish_connection :adapter => "sqlite3", :database => ":memory:"
      ActiveRecord::Migration.suppress_messages do
        begin
          require File.expand_path("#{path}/schema.rb", File.dirname(__FILE__))
        rescue LoadError
        end
      end
      
      # Load domain models for this example.
      Dir["#{path}/**/*.rb"].each do |model|
        require File.expand_path(model, File.dirname(__FILE__))
      end
      
      # Skip empty domain models.
      next if ActiveRecord::Base.descendants.empty?

      puts "#{ActiveRecord::Base.descendants.length} models"
      [:simple, :advanced].each do |notation|
        filename = File.expand_path("examples/#{name}#{notation != :simple ? "-#{notation}" : ""}", File.dirname(__FILE__))

        default_options = { :notation => notation, :filename => filename, :attributes => [:regular],
          :title => name.classify + " domain model" }

        specific_options = eval((File.read("#{path}/options.rb") rescue "")) || {}

        # Generate ERD.
        RailsERD::Diagram::Graphviz.create(default_options.merge(specific_options))
      end
    ensure
      # Completely remove all loaded Active Record models.
      ActiveRecord::Base.descendants.each do |model|
        Object.send :remove_const, model.name.to_sym rescue nil
      end
      ActiveRecord::Base.direct_descendants.clear
      Arel::Relation.send :class_variable_set, :@@connection_tables_primary_keys, {}
      ActiveSupport::Dependencies::Reference.clear!
    end
  end
end
