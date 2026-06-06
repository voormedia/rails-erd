# frozen_string_literal: true

require "rails_erd/diagram"
require "erb"

module RailsERD
  class Diagram
    class Mermaid < Diagram

      attr_accessor :graph

      setup do
        self.graph = [diagram_type]

        # hard code to RL to make it easier to view diagrams from GitHub
        self.graph << "\tdirection RL"
      end

      each_entity do |entity, attributes|
        if er_diagram?
          # Build entity block as a single string to avoid uniq issues with closing braces
          entity_lines = ["\t#{entity} {"]
          attributes.each do |attr|
            key_marker = attribute_key_marker(attr)
            entity_lines << "\t\t#{attr.type} #{attr.name}#{key_marker}"
          end
          entity_lines << "\t}"
          graph << entity_lines.join("\n")
        else
          graph << "\tclass `#{entity}`"
          attributes.each do |attr|
            graph << "\t`#{entity}` : +#{attr.type} #{attr.name}"
          end
        end
      end

      each_specialization do |specialization|
        from, to = specialization.generalized, specialization.specialized
        if er_diagram?
          # erDiagram doesn't have a direct polymorphic notation, use inheritance-like
          graph << "\t#{from.name} ||--o{ #{to.name} : \"specializes\""
        else
          graph << "\t<<polymorphic>> `#{specialization.generalized}`"
          graph << "\t #{from.name} <|-- #{to.name}"
        end
      end

      each_relationship do |relationship|
        from, to = relationship.source, relationship.destination
        next unless from && to

        if er_diagram?
          graph << "\t#{from.name} #{er_relation_notation(relationship)} #{to.name} : \"\""

          from.children.each do |child|
            graph << "\t#{child.name} #{er_relation_notation(relationship)} #{to.name} : \"\""
          end

          to.children.each do |child|
            graph << "\t#{from.name} #{er_relation_notation(relationship)} #{child.name} : \"\""
          end
        else
          graph << "\t`#{from.name}` #{relation_arrow(relationship)} `#{to.name}`"

          from.children.each do |child|
            graph << "\t`#{child.name}` #{relation_arrow(relationship)} `#{to.name}`"
          end

          to.children.each do |child|
            graph << "\t`#{from.name}` #{relation_arrow(relationship)} `#{child.name}`"
          end
        end
      end

      save do
        raise "Saving diagram failed!\nOutput directory '#{File.dirname(filename)}' does not exist." unless File.directory?(File.dirname(filename))

        File.write(filename.gsub(/\s/,"_"), graph.uniq.join("\n"))
        filename
      end

      def filename
        "#{options.filename}.mmd"
      end

      def diagram_type
        er_diagram? ? "erDiagram" : "classDiagram"
      end

      def er_diagram?
        options[:mermaid_style] == :erdiagram || options[:mermaid_style] == :er
      end

      # erDiagram relationship notation using crow's foot
      # Format: left_cardinality--right_cardinality
      # Cardinality markers:
      #   || = exactly one
      #   o| = zero or one
      #   }| = one or more
      #   }o = zero or more
      def er_relation_notation(relationship)
        line = relationship.indirect? ? ".." : "--"

        # Left side (source cardinality - how many source entities relate to one destination)
        left = if relationship.many_to?
          relationship.source_optional? ? "o{" : "|{"
        else
          relationship.source_optional? ? "o|" : "||"
        end

        # Right side (destination cardinality - how many destination entities relate to one source)
        right = if relationship.to_many?
          relationship.destination_optional? ? "}o" : "}|"
        else
          relationship.destination_optional? ? "|o" : "||"
        end

        "#{left}#{line}#{right}"
      end

      def attribute_key_marker(attr)
        markers = []
        markers << "PK" if attr.primary_key?
        markers << "FK" if attr.foreign_key?
        markers.empty? ? "" : " #{markers.join(',')}"
      end

      # classDiagram relationship arrows (legacy)
      def relation_arrow(relationship)
        arrow_body = arrow_body relationship
        arrow_head = arrow_head relationship
        arrow_tail = arrow_tail relationship

        "#{arrow_tail}#{arrow_body}#{arrow_head}"
      end

      def arrow_body(relationship)
        relationship.indirect? ? ".." : "--"
      end

      def arrow_head(relationship)
        relationship.to_many? ?  ">" : ""
      end

      def arrow_tail(relationship)
        relationship.many_to? ? "<" : ""
      end

    end
  end
end
