# encoding: utf-8
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
    # filename:: The file basename of the generated diagram. Defaults to +ERD+,
    #            or any other extension based on the file type.
    # filetype:: The file type of the generated diagram. Defaults to +pdf+, which
    #            is the recommended format. Other formats may render significantly
    #            worse than a PDF file. The available formats depend on your installation
    #            of Graphviz.
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
        :nodesep => 0.4,
        :pad => "0.4,0.4",
        :margin => "0,0",
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
        :arrowsize => 0.9,
        :penwidth => 1.0,
        :labelangle => 32,
        :labeldistance => 1.8,
        :fontsize => 7  
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
          options[:arrowsize] = 0.7
          options[:arrowhead] = relationship.to_many? ? :vee : :none
          options[:arrowtail] = relationship.many_to? ? :vee : :none
          ranges = [relationship.cardinality.destination_range, relationship.cardinality.source_range].map do |range|
            if range.min == range.max
              "#{range.min}"
            else
              "#{range.min}..#{range.max == Domain::Relationship::N ? "∗" : range.max}"
            end
          end
          options[:headlabel], options[:taillabel] = *ranges
        },
        
        # Arrow for to/from many, open or closed dots for optional/mandatory.
        :bachman => lambda { |relationship, options|
          # Participation is "look-here".
          dst = relationship.source_optional? ? "odot" : "dot"
          src = relationship.destination_optional? ? "odot" : "dot"
          # Cardinality is "look-across".
          dst << "normal" if relationship.to_many?
          src << "normal" if relationship.many_to?
          options[:arrowsize] = 0.6
          options[:arrowhead], options[:arrowtail] = dst, src
        }
      }
      
      attr_accessor :graph

      setup do
        self.graph = GraphViz.digraph(domain.name)

        # Set all default attributes.
        GRAPH_ATTRIBUTES.each { |attribute, value| graph[attribute] = value }
        NODE_ATTRIBUTES.each  { |attribute, value| graph.node[attribute] = value }
        EDGE_ATTRIBUTES.each  { |attribute, value| graph.edge[attribute] = value }

        # Switch rank direction if we're creating a vertically oriented graph.
        graph[:rankdir] = :TB if vertical?
        
        # Title of the graph itself.
        graph[:label] = "#{title}\\n\\n" if title
      end
      
      save do
        raise "Saving diagram failed. Output directory '#{File.dirname(filename)}' does not exist." unless File.directory?(File.dirname(filename))
        begin
          graph.output(filetype => filename)
          filename
        rescue StandardError => e
          raise "Saving diagram failed. Verify that Graphviz is installed or select filetype=dot."
        end
      end

      each_entity do |entity, attributes|
        graph.add_node entity.name, entity_options(entity, attributes)
      end

      each_relationship do |relationship|
        graph.add_edge graph.get_node(relationship.source.name), graph.get_node(relationship.destination.name),
          relationship_options(relationship)
      end
      
      each_specialization do |specialization|
        graph.add_edge graph.get_node(specialization.generalized.name), graph.get_node(specialization.specialized.name),
          specialization_options(specialization)
      end

      private
      
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

      # Returns the title to be used for the graph.
      def title
        case options.title
        when false then nil
        when true then
          if domain.name then "#{domain.name} domain model" else "Domain model" end
        else options.title
        end
      end
      
      # Returns the file name that will be used when saving the diagram.
      def filename
        "#{options.filename}.#{options.filetype}"
      end
      
      # Returns the default file extension to be used when saving the diagram.
      def filetype
        if options.filetype.to_sym == :dot then :none else options.filetype.to_sym end
      end

      def entity_options(entity, attributes)
        entity_style_options(entity, attributes).tap do |opts|
          opts[:label] = "<#{NODE_LABEL_TEMPLATE.result(binding)}>"
        end
      end
      
      def relationship_options(relationship)
        relationship_style_options(relationship).tap do |opts|
          # Edges with a higher weight are optimised to be shorter and straighter.
          opts[:weight] = relationship.strength
          
          # Indirect relationships should not influence node ranks.
          opts[:constraint] = false if relationship.indirect?
        end
      end

      def specialization_options(specialization)
        specialization_style_options(specialization)
      end
      
      # The style options below are only used for notation-specific properties
      # of the diagram. They may be overridden in subclasses.
      
      # Style of entity nodes.
      def entity_style_options(entity, attributes)
        {}.tap do |opts|
          opts[:fontcolor] = opts[:color] = :grey60 if entity.specialized?
        end
      end
      
      # Returns an options hash that defines the (cardinality) style for the
      # relationship.
      def relationship_style_options(relationship)
        {}.tap do |opts|
          opts[:style] = :dotted if relationship.indirect?
          
          # Let cardinality style callbacks draw arrow heads and tails.
          CARDINALITY_STYLES[options.notation][relationship, opts]
        end
      end
      
      # Style of specializations.
      def specialization_style_options(specialization)
        { :color => :grey60, :arrowtail => :onormal, :arrowhead => :none, :arrowsize => 1.2 }
      end
    end
  end
end