# encoding: utf-8
require "rails_erd/diagram"
require "graphviz"
require "erb"

# Fix bad RegEx test in Ruby-Graphviz.
GraphViz::Types::LblString.class_eval do
  def output # @private :nodoc:
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
    # command line graph generation, you can use:
    #
    #   % rake erd
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
      NODE_LABEL_TEMPLATES = {
        html:   "node.html.erb",
        record: "node.record.erb"
      } # @private :nodoc:

      NODE_WIDTH = 130 # @private :nodoc:

      FONTS = Config.font_names_based_on_os

      # Default graph attributes.
      GRAPH_ATTRIBUTES = {
        rankdir:     :LR,
        ranksep:     0.5,
        nodesep:     0.4,
        pad:         "0.4,0.4",
        margin:      "0,0",
        concentrate: true,
        labelloc:    :t,
        fontsize:    13,
        fontname:    FONTS[:bold],
        splines:     'spline'
      }

      # Default node attributes.
      NODE_ATTRIBUTES = {
        shape:    "Mrecord",
        fontsize: 10,
        fontname: FONTS[:normal],
        margin:   "0.07,0.05",
        penwidth: 1.0
      }

      # Default edge attributes.
      EDGE_ATTRIBUTES = {
        fontname:      FONTS[:normal],
        fontsize:      7,
        dir:           :both,
        arrowsize:     0.9,
        penwidth:      1.0,
        labelangle:    32,
        labeldistance: 1.8,
      }

      module Simple
        def entity_style(entity, attributes)
          {}.tap do |options|
            options[:fontcolor] = options[:color] = :grey60 if entity.virtual?
          end
        end

        def relationship_style(relationship)
          {}.tap do |options|
            options[:style] = :dotted if relationship.indirect?

            # Closed arrows for to/from many.
            options[:arrowhead] = relationship.to_many? ? "normal" : "none"
            options[:arrowtail] = relationship.many_to? ? "normal" : "none"
          end
        end

        def specialization_style(specialization)
          { color:     :grey60,
            arrowtail: :onormal,
            arrowhead: :none,
            arrowsize: 1.2 }
        end
      end

      module Crowsfoot
        include Simple
        def relationship_style(relationship)
          {}.tap do |options|
            options[:style] = :dotted if relationship.indirect?

            # Cardinality is "look-across".
            dst = relationship.to_many? ? "crow" : "tee"
            src = relationship.many_to? ? "crow" : "tee"

            # Participation is "look-across".
            dst << (relationship.destination_optional? ? "odot" : "tee")
            src << (relationship.source_optional? ? "odot" : "tee")

            options[:arrowsize] = 0.6
            options[:arrowhead], options[:arrowtail] = dst, src
          end
        end
      end

      module Bachman
        include Simple
        def relationship_style(relationship)
          {}.tap do |options|
            options[:style] = :dotted if relationship.indirect?

            # Participation is "look-here".
            dst = relationship.source_optional? ? "odot" : "dot"
            src = relationship.destination_optional? ? "odot" : "dot"

            # Cardinality is "look-across".
            dst << "normal" if relationship.to_many?
            src << "normal" if relationship.many_to?

            options[:arrowsize] = 0.6
            options[:arrowhead], options[:arrowtail] = dst, src
          end
        end
      end

      module Uml
        include Simple
        def relationship_style(relationship)
          {}.tap do |options|
            options[:style] = :dotted if relationship.indirect?

            options[:arrowsize] = 0.7
            options[:arrowhead] = relationship.to_many? ? "vee" : "none"
            options[:arrowtail] = relationship.many_to? ? "vee" : "none"

            ranges = [relationship.cardinality.destination_range, relationship.cardinality.source_range].map do |range|
              if range.min == range.max
                "#{range.min}"
              else
                "#{range.min}..#{range.max == Domain::Relationship::N ? "∗" : range.max}"
              end
            end
            options[:headlabel], options[:taillabel] = *ranges
          end
        end
      end

      attr_accessor :graph

      setup do
        self.graph = GraphViz.digraph(domain.name)

        # Set all default attributes.
        GRAPH_ATTRIBUTES.each { |attribute, value| graph[attribute] = value }
        NODE_ATTRIBUTES.each  { |attribute, value| graph.node[attribute] = value }
        EDGE_ATTRIBUTES.each  { |attribute, value| graph.edge[attribute] = value }

        # Switch rank direction if we're creating a vertically oriented graph.
        graph[:rankdir] = (options.orientation == "vertical") ? :LR : :TB

        # Title of the graph itself.
        graph[:label] = "#{title}\\n\\n" if title

        # Style of splines
        graph[:splines] = options.splines unless options.splines.nil?

        # Setup notation options.
        extend self.class.const_get(options.notation.to_s.capitalize.to_sym)
      end

      save do
        raise "Saving diagram failed!\nOutput directory '#{File.dirname(filename)}' does not exist." unless File.directory?(File.dirname(filename))

        begin
          # GraphViz doesn't like spaces in the filename
          graph.output(filetype => filename.gsub(/\s/,"_"))
          filename
        rescue RuntimeError => e
          raise "Saving diagram failed!\nGraphviz produced errors. Verify it " +
                  "has support for filetype=#{options.filetype}, or use " +
                  "filetype=dot.\nOriginal error: #{e.message.split("\n").last}"
        rescue StandardError => e
          raise "Saving diagram failed!\nVerify that Graphviz is installed " +
                  "and in your path, or use filetype=dot."
        end
      end

      each_entity do |entity, attributes|
        if options[:cluster] && entity.namespace
          cluster_name = "cluster_#{entity.namespace}"
          cluster = graph.get_graph(cluster_name) ||
                    graph.add_graph(cluster_name, label: entity.namespace)
          draw_cluster_node cluster, entity.name, entity_options(entity, attributes)
        else
          draw_node entity.name, entity_options(entity, attributes)
        end
      end

      each_specialization do |specialization|
        from, to = specialization.generalized, specialization.specialized
        draw_edge from.name, to.name, specialization_options(specialization)
      end

      each_relationship do |relationship|
        from, to = relationship.source, relationship.destination
        unless draw_edge from.name, to.name, relationship_options(relationship)
          from.children.each do |child|
            draw_edge child.name, to.name, relationship_options(relationship)
          end
          to.children.each do |child|
            draw_edge from.name, child.name, relationship_options(relationship)
          end
        end
      end

      private

      def node_exists?(name)
        !!graph.search_node(escape_name(name))
      end

      def draw_node(name, options)
        graph.add_nodes escape_name(name), options
      end

      def draw_cluster_node(cluster, name, options)
        cluster.add_nodes escape_name(name), options
      end

      def draw_edge(from, to, options)
        graph.add_edges graph.search_node(escape_name(from)), graph.search_node(escape_name(to)), options if node_exists?(from) and node_exists?(to)
      end

      def escape_name(name)
        "m_#{name}"
      end

      # Returns the title to be used for the graph.
      def title
        case options.title
        when false then nil
        when true
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
        label = options[:markup] ? "<#{read_template(:html).result(binding)}>" : "#{read_template(:record).result(binding)}"
        entity_style(entity, attributes).merge :label => label
      end

      def relationship_options(relationship)
        relationship_style(relationship).tap do |options|
          # Edges with a higher weight are optimized to be shorter and straighter.
          options[:weight] = relationship.strength

          # Indirect relationships should not influence node ranks.
          options[:constraint] = false if relationship.indirect?
        end
      end

      def specialization_options(specialization)
        specialization_style(specialization)
      end

      def read_template(type)
        ERB.new(File.read(File.expand_path("templates/#{NODE_LABEL_TEMPLATES[type]}", File.dirname(__FILE__))), nil, "<>")
      end
    end
  end
end
