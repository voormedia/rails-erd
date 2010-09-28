require "rails_erd/diagram"
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
  class Diagram
    # Create Graphviz-based diagrams based on the domain model. For easy
    # command line graph generation, you can use rake:
    #
    #   % rake erd
    #
    # Please see the README.rdoc file for more details on how to use Rails ERD
    # from the command line.
    #
    # === Options
    #
    # The following options are supported:
    #
    # file_type:: The file type of the generated diagram. Defaults to +pdf+, which
    #             is the recommended format. Other formats may render significantly
    #             worse than a PDF file. The available formats depend on your installation
    #             of Graphviz.
    # orientation:: The direction of the hierarchy of entities. Either +horizontal+
    #               or +vertical+. Defaults to +horizontal+. The orientation of the
    #               PDF that is generated depends on the amount of hierarchy
    #               in your models.    
    class Graphviz < Diagram
      NODE_LABEL_TEMPLATE = ERB.new(File.read(File.expand_path("templates/node.erb", File.dirname(__FILE__))), nil, "<>") # @private :nodoc:

      NODE_WIDTH = 130 # @private :nodoc:
      
      # Default graph attributes.
      GRAPH_ATTRIBUTES = {
        :rankdir => :LR,
        :ranksep => 0.5,
        :nodesep => 0.35,
        :margin => "0.4,0.4",
        :concentrate => true,
        :labelloc => :t,
        :fontsize => 13,
        :fontname => "Arial Bold",
        :remincross => true,
        :outputorder => :edgesfirst
      }

      # Default node attributes.
      NODE_ATTRIBUTES = {
        :shape => "Mrecord",
        :fontsize => 10,
        :fontname => "Arial",
        :margin => "0.07,0.05",
        :penwidth => 1.0
      }

      # Default edge attributes.
      EDGE_ATTRIBUTES = {
        :fontname => "Arial",
        :fontsize => 8,
        :dir => :both,
        :arrowsize => 0.7,
        :penwidth => 1.0
      }

      def graph
        @graph ||= GraphViz.digraph(@domain.name) do |graph|
          # Set all default attributes.
          GRAPH_ATTRIBUTES.each { |attribute, value| graph[attribute] = value }
          NODE_ATTRIBUTES.each  { |attribute, value| graph.node[attribute] = value }
          EDGE_ATTRIBUTES.each  { |attribute, value| graph.edge[attribute] = value }

          # Switch rank direction if we're told to create a vertically
          # oriented graph.
          graph[:rankdir] = :TB if vertical?
          
          # Title of the graph itself.
          graph[:label] = "#{@domain.name} domain model\\n\\n"
        end
      end
      
      # Save the diagram and return the file name that was written to.
      def save
        graph.output(options.file_type.to_sym => file_name)
        file_name
      end

      protected

      def process_entity(entity, attributes)
        graph.add_node entity.name, entity_options(entity, attributes)
      end

      def process_relationship(relationship)
        graph.add_edge graph.get_node(relationship.source.name), graph.get_node(relationship.destination.name),
          relationship_options(relationship)
      end

      # Returns +true+ if the layout or hierarchy of the diagram should be
      # horizontally oriented.
      def horizontal?
        options.orientation == :horizontal
      end

      # Returns +true+ if the layout or hierarchy of the diagram should be
      # vertically oriented.
      def vertical?
        !horizontal?
      end

      private
      
      # Returns the file name that will be used when saving the diagram.
      def file_name
        "ERD.#{options.file_type}"
      end

      # Returns an options hash based on the given entity and its attributes.
      def entity_options(entity, attributes)
        { :label => "<#{NODE_LABEL_TEMPLATE.result(binding)}>" }
      end
      
      # Returns an options hash 
      def relationship_options(relationship)
        {}.tap do |options|
          options[:arrowhead] = relationship.cardinality.one_to_one?   ? :dot : :normal
          options[:arrowtail] = relationship.cardinality.many_to_many? ? :normal : :dot
          options[:weight] = relationship.strength
          if relationship.indirect?
            options[:style] = :dotted
            options[:constraint] = false
          end
        end
      end
    end
  end
end