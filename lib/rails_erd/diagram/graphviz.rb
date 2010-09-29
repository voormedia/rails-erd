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
    # file_name:: The file name of the generated diagram. Defaults to +ERD.pdf+,
    #             or any other extension based on the file type.
    # file_type:: The file type of the generated diagram. Defaults to +pdf+, which
    #             is the recommended format. Other formats may render significantly
    #             worse than a PDF file. The available formats depend on your installation
    #             of Graphviz.
    # notation:: The cardinality notation to be used. Can be +:simple+ or
    #            +:bachman+. Refer to README.rdoc or to the examples on the project
    #            homepage for more information and examples.
    # orientation:: The direction of the hierarchy of entities. Either +:horizontal+
    #               or +:vertical+. Defaults to +horizontal+. The orientation of the
    #               PDF that is generated depends on the amount of hierarchy
    #               in your models.
    # title:: The title to add at the top of the diagram. Defaults to 
    #         <tt>"YourApplication domain model"</tt>.
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
        :arrowsize => 0.8,
        :penwidth => 1.0
      }
      
      # Define different styles to draw the cardinality of relationships.
      CARDINALITY_STYLES = {
        # Closed arrows for to/from many.
        :simple => lambda { |relationship, options|
          options[:arrowhead] = relationship.to_many? ? :normal : :none
          options[:arrowtail] = relationship.many_to? ? :normal : :none
        },

        # Closed arrow for to/from many, UML ranges at each end.
        :uml => lambda { |relationship, options|
          CARDINALITY_STYLES[:simple][relationship, options]
          # TODO
        },
        
        # Arrow for to/from many, open or closed dots for optional/mandatory.
        :bachman => lambda { |relationship, options|
          dst = relationship.destination_optional? ? "odot" : "dot"
          src = relationship.source_optional? ? "odot" : "dot"
          dst << "normal" if relationship.to_many?
          src << "normal" if relationship.many_to?
          options[:arrowhead], options[:arrowtail] = dst, src
        }
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
          graph[:label] = "#{title}\\n\\n" if title
        end
      end
      
      # Save the diagram and return the file name that was written to.
      def save
        check_version!
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
      
      def check_version!
        version_output = `dot -V 2>&1`.strip rescue nil
        version = if version_output =~ %r{graphviz\s+version\s+(\d+\.\d+\.\d+)}i
          parts = $1.split(".").map(&:to_i)
          if parts.size >= 2 and parts[0] <= 2 and parts[1] < 22
            # Graphviz < 2.22 (silently) fails in many cases.
            warn "Graphviz appears to be older than version 2.22. Diagram generation may be problematic, upgrading is recommended."
          end
        end
      end
      
      # Returns the title to be used for the graph.
      def title
        case options.title
        when false then nil
        when true then
          if @domain.name then "#{@domain.name} domain model" else "Domain model" end
        else options.title
        end
      end
      
      # Returns the file name that will be used when saving the diagram.
      def file_name
        options.file_name or "ERD.#{file_extension}"
      end
      
      # Returns the default file extension to be used when saving the diagram.
      def file_extension
        if options.file_type == :none then :dot else options.file_type end
      end

      # Returns an options hash based on the given entity and its attributes.
      def entity_options(entity, attributes)
        { :label => "<#{NODE_LABEL_TEMPLATE.result(binding)}>" }
      end
      
      # Returns an options hash 
      def relationship_options(relationship)
        relationship_style_options(relationship).tap do |opts|
          # Edges with a higher weight are optimised to be shorter and straighter.
          opts[:weight] = relationship.strength
          
          # Indirect relationships should not influence node ranks.
          opts[:constraint] = false if relationship.indirect?
        end
      end
      
      # Returns an options hash that defines the (cardinality) style for the
      # relationship.
      def relationship_style_options(relationship)
        {}.tap do |opts|
          opts[:style] = :dotted if relationship.indirect?
          
          # Let cardinality style callbacks draw arrow heads and tails.
          CARDINALITY_STYLES[options.notation || :simple][relationship, opts]
        end
      end
    end
  end
end