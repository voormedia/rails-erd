require "rubygems"
require "bundler/setup"

require "active_record"
require "rails_erd/diagram/graphviz"

output_dir = File.expand_path("output", ".")
FileUtils.mkdir_p output_dir
Dir["#{File.dirname(__FILE__)}/*/*"].each do |path|
  name = File.basename(path)
  print "==> Generating diagram for #{name.capitalize}... "
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
    [:simple, :bachman].each do |notation|
      filename = File.expand_path("#{output_dir}/#{name}#{notation != :simple ? "-#{notation}" : ""}", File.dirname(__FILE__))

      default_options = { :notation => notation, :filename => filename, :attributes => [:content],
        :title => name.classify + " domain model" }

      specific_options = eval((File.read("#{path}/options.rb") rescue "")) || {}

      # Generate ERD.
      outfile = RailsERD::Diagram::Graphviz.create(default_options.merge(specific_options))

      puts "    - #{notation} notation saved to #{outfile}"
    end
    puts
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
