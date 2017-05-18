require 'graphviz/utils'

def say(message)
  puts message unless Rake.application.options.silent
end

namespace :erd do
  task :check_dependencies do
    include GraphViz::Utils
    unless find_executable("dot", nil)
      raise "Unable to find GraphViz's \"dot\" executable. Please " \
            "visit https://voormedia.github.io/rails-erd/install.html for installation instructions."
    end
  end

  task :options do
    (RailsERD.options.keys.map(&:to_s) & ENV.keys).each do |option|
      RailsERD.options[option.to_sym] = case ENV[option]
      when "true", "yes" then true
      when "false", "no" then false
      when /,/ then ENV[option].split(/\s*,\s*/)
      else ENV[option].to_sym
      end
    end
  end

  task :load_models do
    say "Loading application environment..."
    Rake::Task[:environment].invoke

    say "Loading code in search of Active Record models..."
    begin
      Rails.application.eager_load!

      if Rails.application.respond_to?(:config) && !Rails.application.config.nil?
        Rails.application.config.eager_load_namespaces.each(&:eager_load!) if Rails.application.config.respond_to?(:eager_load_namespaces)
      end
    rescue Exception => err
      if Rake.application.options.trace
        raise
      else
        trace = Rails.backtrace_cleaner.clean(err.backtrace)
        error = (["Loading models failed!\nError occurred while loading application: #{err} (#{err.class})"] + trace).join("\n    ")
        raise error
      end
    end

    raise "Active Record was not loaded." unless defined? ActiveRecord
  end

  task :generate => [:check_dependencies, :options, :load_models] do
    say "Generating Entity-Relationship Diagram for #{ActiveRecord::Base.descendants.length} models..."

    require "rails_erd/diagram/graphviz"
    file = RailsERD::Diagram::Graphviz.create

    say "Done! Saved diagram to #{file}."
  end
end

desc "Generate an Entity-Relationship Diagram based on your models"
task :erd => "erd:generate"
