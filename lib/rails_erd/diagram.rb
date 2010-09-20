require "rails_erd/domain"
require "graphviz"
require "erb"

# Fix bad RegEx test in Ruby-Graphviz.
GraphViz::Types::LblString.class_eval do
  def output
    if /^<.*>$/m =~ @data
      @data
    else
      @data.to_s.inspect.gsub("\\\\", "\\")
    end
  end
  alias_method :to_gv, :output
  alias_method :to_s, :output
end

module RailsERD
  # Create Graphviz-based diagrams based on the domain model. For easy
  # command line graph generation, you can use rake:
  #
  #   % rake erd
  #
  # Please see the README.rdoc file for more details on how to use Rails ERD
  # from the command line.
  class Diagram
    NODE_LABEL_TEMPLATE = File.read(File.expand_path("templates/node.erb", File.dirname(__FILE__))) #:nodoc:
    NODE_WIDTH = 130 #:nodoc:
    
    class << self
      # Generate a new domain model based on all <tt>ActiveRecord::Base</tt>
      # subclasses, and create a new diagram. Use the given options for both
      # the domain generation and the diagram generation.
      def generate(options = {})
        new(Domain.generate(options), options).output
      end
    end
    
    attr_reader :options #:nodoc:

    # Create a new diagram based on the given domain.
    def initialize(domain, options = {})
      @domain, @options = domain, RailsERD.options.merge(options)
    end
    
    # Save the diagram.
    def output
      graph.output(options.file_type.to_sym => file_name)
      self
    end
    
    # Returns the file name that will be used when saving the diagram.
    def file_name
      "ERD.#{options.file_type}"
    end
    
    private
    
    def graph
      @graph ||= GraphViz.new(@domain.name, :type => :digraph) do |graph|
        graph[:rankdir] = horizontal? ? :LR : :TB
        graph[:ranksep] = 0.5
        graph[:nodesep] = 0.35
        graph[:margin] = "0.4,0.4"
        graph[:concentrate] = true
        graph[:label] = "#{@domain.name} domain model\\n\\n"
        graph[:labelloc] = :t
        graph[:fontsize] = 13
        graph[:fontname] = "Arial Bold"
        graph[:remincross] = true
        graph[:outputorder] = :edgesfirst

        graph.node[:shape] = "Mrecord"
        graph.node[:fontsize] = 10
        graph.node[:fontname] = "Arial"
        graph.node[:margin] = "0.07,0.05"
        graph.node[:penwidth] = 0.8

        graph.edge[:fontname] = "Arial"
        graph.edge[:fontsize] = 8
        graph.edge[:dir] = :both
        graph.edge[:arrowsize] = 0.7
        graph.edge[:penwidth] = 0.8
        
        nodes = {}

        @domain.entities.each do |entity|
          if options.exclude_unconnected && !entity.connected?
            warn "Skipping unconnected model #{entity.name} (use exclude_unconnected=false to include)"
            next
          end
          
          attributes = entity.attributes.reject { |attribute|
            options.exclude_primary_keys && attribute.primary_key? or
            options.exclude_foreign_keys && attribute.foreign_key? or
            options.exclude_timestamps && attribute.timestamp?
          }
          nodes[entity] = graph.add_node entity.name, :label => "<" + ERB.new(NODE_LABEL_TEMPLATE, nil, "<>").result(binding) + ">"
        end
        
        raise "No (connected) entities found; create your models first!" if nodes.empty?
        
        @domain.relationships.each do |relationship|
          options = {}
          options[:arrowhead] = relationship.cardinality.one_to_one? ? :dot : :normal
          options[:arrowtail] = relationship.cardinality.many_to_many? ? :normal : :dot
          options[:weight] = relationship.strength
          options.merge! :style => :dotted, :constraint => false if relationship.indirect?

          graph.add_edge nodes[relationship.source], nodes[relationship.destination], options
        end
      end
    end
    
    def horizontal?
      options.orientation == :horizontal
    end

    def vertical?
      !horizontal?
    end

    def warn(message)
      puts "Warning: #{message}" unless options.suppress_warnings
    end
  end
end
