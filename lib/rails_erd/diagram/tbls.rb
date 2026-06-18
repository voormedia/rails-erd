# frozen_string_literal: true

require "rails_erd/diagram"
require "json"

module RailsERD
  class Diagram
    # Emits a JSON description of the domain in the tbls schema format
    # (https://github.com/k1LoW/tbls). Consumable by any tbls-compatible tool —
    # for example Liam ERD: `liam erd build --input erd.json --format tbls`.
    #
    # Unlike a schema.rb dump, this reflects the relationships rails-erd derives
    # from ActiveRecord — including FKs that exist only as `belongs_to`
    # associations and not as DB-level constraints.
    class Tbls < Diagram
      attr_accessor :tables_by_name

      setup do
        self.tables_by_name = {}
      end

      each_entity do |entity, _attributes|
        next if entity.generalized?
        next unless entity.model

        table_name = entity.model.table_name
        next if tables_by_name.key?(table_name)

        tables_by_name[table_name] = build_table(entity)
      end

      each_relationship do |relationship|
        next if relationship.indirect?
        next unless relationship.source && relationship.destination
        next if relationship.source.generalized? || relationship.destination.generalized?

        add_foreign_keys(relationship)
      end

      save do
        dir = File.dirname(filename)
        raise "Saving diagram failed!\nOutput directory '#{dir}' does not exist." unless File.directory?(dir)

        File.write(filename, JSON.pretty_generate(schema_payload))
        filename
      end

      def filename
        "#{options.filename}.json"
      end

      private

      def schema_payload
        {
          name: domain.name || "rails-erd",
          tables: tables_by_name.values,
        }
      end

      def build_table(entity)
        model = entity.model
        comment = model.respond_to?(:table_comment) ? model.table_comment : nil
        payload = {
          name: model.table_name,
          type: "BASE TABLE",
          columns: entity.attributes.map { |attr| column_payload(attr) },
          indexes: indexes_payload(model),
          constraints: primary_key_constraints(model),
        }
        payload[:comment] = comment if comment && !comment.empty?
        payload
      end

      def column_payload(attr)
        column = attr.column
        payload = {
          name: column.name,
          type: column.sql_type.to_s,
          nullable: column.null,
        }
        payload[:default] = column.default.to_s unless column.default.nil?
        comment = column.comment if column.respond_to?(:comment)
        payload[:comment] = comment if comment && !comment.empty?
        payload
      end

      def indexes_payload(model)
        return [] unless model.connection.respond_to?(:indexes)

        model.connection.indexes(model.table_name).map do |idx|
          columns = Array(idx.columns).map(&:to_s)
          {
            name: idx.name,
            def: index_def(model.table_name, idx, columns),
            table: model.table_name,
            columns: columns,
          }
        end
      rescue StandardError
        []
      end

      def index_def(table_name, idx, columns)
        unique = idx.unique ? "UNIQUE " : ""
        "CREATE #{unique}INDEX #{idx.name} ON #{table_name} (#{columns.join(", ")})"
      end

      def primary_key_constraints(model)
        pk = Array(model.primary_key).compact.map(&:to_s)
        return [] if pk.empty?

        [{
          name: "#{model.table_name}_pkey",
          type: "PRIMARY KEY",
          def: "PRIMARY KEY (#{pk.join(", ")})",
          table: model.table_name,
          referenced_table: "",
          columns: pk,
        }]
      end

      def add_foreign_keys(relationship)
        relationship.associations.each do |assoc|
          next if assoc.options[:polymorphic]
          next unless assoc.belongs_to?

          fk_columns = Array(assoc.send(Domain.foreign_key_method_name)).map(&:to_s).reject(&:empty?)
          next if fk_columns.empty?

          target_model = safe_klass(assoc)
          next unless target_model

          target_pk = Array(target_model.primary_key).compact.map(&:to_s)
          next if target_pk.empty?

          owning_table = assoc.active_record.table_name
          target_table = target_model.table_name
          name = "fk_#{owning_table}_#{fk_columns.join("_")}"

          add_constraint(owning_table, {
            name: name,
            type: "FOREIGN KEY",
            def: "FOREIGN KEY (#{fk_columns.join(", ")}) REFERENCES #{target_table}(#{target_pk.join(", ")})",
            table: owning_table,
            referenced_table: target_table,
            columns: fk_columns,
            referenced_columns: target_pk,
          })
        end
      end

      def safe_klass(association)
        association.klass
      rescue NameError
        nil
      end

      def add_constraint(table_name, constraint)
        table = tables_by_name[table_name]
        return unless table
        return if table[:constraints].any? { |c| c[:name] == constraint[:name] }

        table[:constraints] << constraint
      end
    end
  end
end
