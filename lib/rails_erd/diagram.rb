require "rails_erd/domain"
require "graphviz"

module RailsERD
  class Diagram
    NODE_LABEL_TEMPLATE = File.read(File.expand_path("templates/node.erb", File.dirname(__FILE__))) #:nodoc:
    NODE_WIDTH = 130 #:nodoc:
    
    class << self
      def generate(options = {})
        new(Domain.generate(options), options).output
      end
    end
    
    attr_reader :options #:nodoc:

    def initialize(domain, options = {})
      @domain, @options = domain, RailsERD.options.merge(options)
    end
    
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

        graph.edge[:fontname] = "Arial"
        graph.edge[:fontsize] = 8
        graph.edge[:dir] = :both
        graph.edge[:arrowsize] = 0.8
        
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
          
          nodes[entity] = graph.add_node entity.name, :html => ERB.new(NODE_LABEL_TEMPLATE, nil, "<>").result(binding)
        end

        @domain.relationships.each do |relationship|
          options = {}
          options[:arrowhead] = relationship.cardinality.one_to_one? ? :dot : :normal
          options[:arrowtail] = relationship.cardinality.many_to_many? ? :normal : :dot
          options[:weight] = relationship.strength
          options.merge! :style => :dashed, :constraint => false if relationship.indirect?

          graph.add_edge nodes[relationship.source], nodes[relationship.destination], options
        end
      end
    end
    
    def output
      graph.output(options.type.to_sym => file_name)
      self
    end
    
    def file_name
      "ERD.#{options.type}"
    end
    
    private
    
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
