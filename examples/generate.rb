require "rubygems"
require "bundler/setup"

require "active_record"
require "rails_erd/diagram/graphviz"
require "active_support/dependencies"

output_dir = File.expand_path("output", ".")
FileUtils.mkdir_p output_dir
Dir["#{File.dirname(__FILE__)}/*/*"].each do |path|
  name = File.basename(path)
  print "=> Generating domain for #{name.camelize}... "
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
    ActiveSupport::Dependencies.autoload_paths = ["#{path}/models"]
    Dir["#{path}/{lib,models}/**/*.rb"].each do |model|
      require File.expand_path(model, File.dirname(__FILE__))
    end

    # Skip empty domain models.
    next if ActiveRecord::Base.descendants.empty?

    puts "#{ActiveRecord::Base.descendants.length} models"
    domain = RailsERD::Domain.generate

    [:simple, :bachman].each do |notation|
      [:dot, :pdf].each do |filetype|
        filename = File.expand_path("#{output_dir}/#{name}#{notation != :simple ? "-#{notation}" : ""}", File.dirname(__FILE__))

        default_options = { :notation => notation, :filetype => filetype, :filename => filename,
          :title => name.camelize + " domain model" }

        specific_options = eval((File.read("#{path}/options.rb") rescue "")) || {}

        # Generate ERD.
        outfile = RailsERD::Diagram::Graphviz.new(domain, default_options.merge(specific_options)).create

        puts "   - #{notation} notation saved to #{outfile}"
      end
    end
    puts
  ensure
    # Completely remove all loaded Active Record models.
    ActiveRecord::Base.descendants.each do |model|
      Object.send :remove_const, model.name.to_sym rescue nil
    end

    if ActiveRecord.version >= Gem::Version.new("7.0.0")
      ActiveRecord::Base.subclasses.clear
    else
      ActiveRecord::Base.direct_descendants.clear
    end

    if Arel.const_defined?(:Relation)
      Arel::Relation.send :class_variable_set, :@@connection_tables_primary_keys, {}
    end
    ActiveSupport::Dependencies::Reference.clear!
  end
end
