require "choice"

Choice.options do
  separator ""
  separator "Diagram options:"

  option :title do
    long "--title=TITLE"
    desc "Replace default diagram title with a custom one."
  end

  option :notation do
    long "--notation=STYLE"
    desc "Diagram notation style, one of simple, bachman, uml or crowsfoot."
  end

  option :attributes do
    long "--attributes=TYPE,..."
    desc "Attribute groups to display: false, content, primary_keys, foreign_keys, timestamps and/or inheritance."
  end

  option :orientation do
    long "--orientation=ORIENTATION"
    desc "Orientation of diagram, either horizontal (default) or vertical."
  end

  option :inheritance do
    long "--inheritance"
    desc "Display (single table) inheritance relationships."
  end

  option :polymorphism do
    long "--polymorphism"
    desc "Display polymorphic and abstract entities."
  end

  option :no_indirect do
    long "--direct"
    desc "Omit indirect relationships (through other entities)."
  end

  option :no_disconnected do
    long "--connected"
    desc "Omit entities without relationships."
  end

  option :only do
    long "--only"
    desc "Filter to only include listed models in diagram."
  end

  option :only_recursion_depth do
    long "--only_recursion_depth=INTEGER"
    desc "Recurses into relations specified by --only upto a depth N."
  end

  option :exclude do
    long "--exclude"
    desc "Filter to exclude listed models in diagram."
  end

  option :sort do
    long "--sort=BOOLEAN"
    desc "Sort attribute list alphabetically"
  end

  option :prepend_primary do
    long "--prepend_primary=BOOLEAN"
    desc "Ensure primary key is at start of attribute list"
  end

  option :cluster do
    long "--cluster"
    desc "Display models in subgraphs based on their namespace."
  end

  option :splines do
    long "--splines=SPLINE_TYPE"
    desc "Control how edges are represented. See http://www.graphviz.org/doc/info/attrs.html#d:splines for values."
  end

  separator ""
  separator "Output options:"

  option :filename do
    long "--filename=FILENAME"
    desc "Basename of the output diagram."
  end

  option :filetype do
    long "--filetype=TYPE"
    desc "Output file type. Available types depend on the diagram renderer."
  end

  option :no_markup do
    long "--no-markup"
    desc "Disable markup for enhanced compatibility of .dot output with other applications."
  end

  option :open do
    long "--open"
    desc "Open the output file after it has been saved."
  end

  separator ""
  separator "Common options:"

  option :help do
    long "--help"
    desc "Display this help message."
  end

  option :debug do
    long "--debug"
    desc "Show stack traces when an error occurs."
  end

  option :version do
    short "-v"
    long "--version"
    desc "Show version and quit."
    action do
      require "rails_erd/version"
      $stderr.puts RailsERD::BANNER
      exit
    end
  end
end

module RailsERD
  class CLI
    attr_reader :path, :options

    class << self
      def start
        path = Choice.rest.first || Dir.pwd
        options = Choice.choices.each_with_object({}) do |(key, value), opts|
          if key.start_with? "no_"
            opts[key.gsub("no_", "").to_sym] = !value
          elsif value.to_s.include? ","
            opts[key.to_sym] = value.split(",").map(&:to_s)
          else
            opts[key.to_sym] = value
          end
        end
        new(path, options).start
      end
    end

    def initialize(path, options)
      @path, @options = path, options
      require "rails_erd/diagram/graphviz"
    end

    def start
      load_application
      create_diagram
    rescue Exception => e
      $stderr.puts "Failed: #{e.class}: #{e.message}"
      $stderr.puts e.backtrace.map { |t| "    from #{t}" } if options[:debug]
    end

    private

    def load_application
      $stderr.puts "Loading application in '#{File.basename(path)}'..."
      begin
        environment_path = "#{path}/config/environment.rb"
        require environment_path
      rescue ::LoadError
        puts "Please create a file in '#{environment_path}' that loads your application environment."
        raise
      end
      if defined? Rails
        Rails.application.eager_load!
        Rails.application.config.eager_load_namespaces.each(&:eager_load!) if Rails.application.config.respond_to?(:eager_load_namespaces)
      end
    rescue TypeError
    end

    def create_diagram
      $stderr.puts "Generating entity-relationship diagram for #{ActiveRecord::Base.descendants.length} models..."
      file = RailsERD::Diagram::Graphviz.create(options)
      $stderr.puts "Diagram saved to '#{file}'."
      `open #{file}` if options[:open]
    end
  end
end
