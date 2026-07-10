# frozen_string_literal: true

require "rails_erd/diagram"
require "erb"

module RailsERD
  class Diagram
    class Mermaid < Diagram

      attr_accessor :graph

      setup do
        self.graph = [diagram_type]

        # Respect orientation option: horizontal = TB (top-down), vertical = LR (left-right)
        direction = (options.orientation.to_s == "vertical") ? "LR" : "TB"
        self.graph << "\tdirection #{direction}"

        # Initialize namespace grouping for clustering
        @entities_by_namespace = Hash.new { |h, k| h[k] = [] }
        @clustering_enabled = options[:cluster] && !er_diagram?
        @clustered_entities_emitted = false

        # Warn if clustering requested with erDiagram (not supported)
        if options[:cluster] && er_diagram? && options[:warn]
          warn "Clustering is not supported with erDiagram style. Use mermaid_style: classdiagram instead."
        end
      end

      each_entity do |entity, attributes|
        if er_diagram?
          # Build entity block as a single string to avoid uniq issues with closing braces
          quoted_entity = quote_entity_name(entity)
          entity_lines = ["\t#{quoted_entity} {"]
          attributes.each do |attr|
            key_marker = attribute_key_marker(attr)
            entity_lines << "\t\t#{attr.type} #{attr.name}#{key_marker}"
          end
          entity_lines << "\t}"
          graph << entity_lines.join("\n")
        elsif @clustering_enabled
          # Collect entities by namespace for later emission
          ns = entity.namespace || ""
          short_name = entity.namespace ? entity.name.split("::").last : entity.name
          entity_block = build_class_diagram_entity(short_name, entity.name, attributes)
          @entities_by_namespace[ns] << entity_block
        else
          graph << "\tclass `#{entity}`"
          attributes.each do |attr|
            graph << "\t`#{entity}` : +#{attr.type} #{attr.name}"
          end
        end
      end

      each_specialization do |specialization|
        # Emit clustered entities before the first specialization (same as relationships)
        if @clustering_enabled && !@clustered_entities_emitted
          emit_clustered_entities
          @clustered_entities_emitted = true
        end

        from, to = specialization.generalized, specialization.specialized
        if er_diagram?
          # erDiagram doesn't have a direct polymorphic notation, use inheritance-like
          graph << "\t#{quote_entity_name(from.name)} ||--o{ #{quote_entity_name(to.name)} : \"specializes\""
        else
          graph << "\t<<polymorphic>> `#{specialization.generalized}`"
          graph << "\t #{from.name} <|-- #{to.name}"
        end
      end

      each_relationship do |relationship|
        # Emit clustered entities before the first relationship
        if @clustering_enabled && !@clustered_entities_emitted
          emit_clustered_entities
          @clustered_entities_emitted = true
        end

        from, to = relationship.source, relationship.destination
        next unless from && to

        if er_diagram?
          graph << "\t#{quote_entity_name(from.name)} #{er_relation_notation(relationship)} #{quote_entity_name(to.name)} : \"\""

          from.children.each do |child|
            graph << "\t#{quote_entity_name(child.name)} #{er_relation_notation(relationship)} #{quote_entity_name(to.name)} : \"\""
          end

          to.children.each do |child|
            graph << "\t#{quote_entity_name(from.name)} #{er_relation_notation(relationship)} #{quote_entity_name(child.name)} : \"\""
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

        # Emit clustered entities if not already emitted (e.g., no relationships)
        if @clustering_enabled && !@clustered_entities_emitted
          emit_clustered_entities
          @clustered_entities_emitted = true
        end

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

      # Quote entity names that contain special characters (like :: for namespaces)
      # Mermaid erDiagram requires double quotes for names with special characters
      def quote_entity_name(name)
        name = name.to_s
        if name.include?("::")
          %("#{name}")
        else
          name
        end
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

      # Build entity lines for classDiagram mode (used in clustering)
      def build_class_diagram_entity(short_name, full_name, attributes)
        lines = ["\t\tclass `#{short_name}`"]
        attributes.each do |attr|
          lines << "\t\t`#{short_name}` : +#{attr.type} #{attr.name}"
        end
        lines
      end

      # Emit entities grouped by namespace for clustering
      def emit_clustered_entities
        # Entities without namespace go first (outside any namespace block)
        @entities_by_namespace[""].each do |entity_lines|
          entity_lines.each { |line| graph << line.sub(/^\t\t/, "\t") }
        end

        # Then emit each namespace block
        @entities_by_namespace.each do |ns, entity_blocks|
          next if ns == ""

          # Convert Ruby namespace (Admin::Users) to Mermaid format (Admin.Users)
          mermaid_ns = ns.gsub("::", ".")
          graph << "\tnamespace #{mermaid_ns} {"
          entity_blocks.each do |entity_lines|
            entity_lines.each { |line| graph << line }
          end
          graph << "\t}"
        end
      end

    end
  end
end
