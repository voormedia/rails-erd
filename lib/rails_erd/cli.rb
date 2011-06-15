require "choice"

Hash.class_eval do
  # Fix deprecation warning in Choice.
  alias_method :index, :key if method_defined? :key
end

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
    default "simple"
  end

  separator ""
  separator "Output options:"

  option :filename do
    long "--filename=FILENAME"
    desc "Basename of the output diagram."
    default "erd"
  end

  option :filetype do
    long "--filetype=TYPE"
    desc "Output file type. Available types depend on the diagram renderer."
    default "pdf"
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

  # Remaining options:
  # :attributes, :content,
  # :disconnected, true,
  ## :filename, "erd",
  ## :filetype, :pdf,
  # :indirect, true,
  # :inheritance, false,
  # :markup, true,
  ## :notation, :simple,
  # :orientation, :horizontal,
  # :polymorphism, false,
  # :warn, true,
  ## :title, true
end

module RailsERD
  class CLI
    attr_reader :path, :options

    class << self
      def start
        path = Choice.rest.first || Dir.pwd
        options = Choice.choices.each_with_object({}) { |(k, v), o| o[k.to_sym] = v }
        new(path, options).start
      end
    end

    def initialize(path, options)
      @path, @options = path, options
      require "rails_erd/diagram/graphviz"
    end

    def start
      load_application
      load_models
      create_diagram
    end

    private

    def load_application
      $stderr.puts "Loading application in '#{File.basename(path)}'..."
      require "#{path}/config/environment"
    end

    def load_models
      $stderr.puts "Loading code in search of models..."
      Rails.application.eager_load!
    end

    def create_diagram
      file = RailsERD::Diagram::Graphviz.create(options)
      $stderr.puts "Diagram saved to '#{file}'."
      `open #{file}` if options[:open]
    end
  end
end
