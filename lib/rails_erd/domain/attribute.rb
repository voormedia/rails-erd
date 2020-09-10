# encoding: utf-8

#--
module RailsERD
  class Domain
    # Describes an entity's attribute. Attributes correspond directly to
    # database columns.
    class Attribute
      TIMESTAMP_NAMES = %w{created_at created_on updated_at updated_on} # @private :nodoc:

      class << self
        def from_model(domain, model) # @private :nodoc:
          attributes = model.columns.collect { |column| new(domain, model, column) }
          attributes.sort! if RailsERD.options[:sort]

          if RailsERD.options[:prepend_primary]
            attributes = prepend_primary(model, attributes)
          end

          attributes
        end

        def prepend_primary(model, attributes)
          primary_key = ActiveRecord::Base.get_primary_key(model)
          primary = attributes.index { |column| column.name == primary_key }

          if primary
            attributes[primary], attributes[0] = attributes[0], attributes[primary]
          end

          attributes
        end
      end

      extend Inspectable
      inspection_attributes :name, :type

      attr_reader :column # @private :nodoc:

      def initialize(domain, model, column) # @private :nodoc:
        @domain, @model, @column = domain, model, column
      end

      # The name of the attribute, equal to the column name.
      def name
        column.name
      end

      # The type of the attribute, equal to the Rails migration type. Can be any
      # of +:string+, +:integer+, +:boolean+, +:text+, etc.
      def type
        column.type or column.sql_type.downcase.to_sym
      end

      # Returns +true+ if this attribute is a content column, that is, if it
      # is not a primary key, foreign key, timestamp, or inheritance column.
      def content?
        !primary_key? and !foreign_key? and !timestamp? and !inheritance?
      end

      # Returns +true+ if this attribute is mandatory. Mandatory attributes
      # either have a presence validation (+validates_presence_of+), or have a
      # <tt>NOT NULL</tt> database constraint.
      def mandatory?
        !column.null or @model.validators_on(name).map(&:kind).include?(:presence)
      end

       def unique?
         @model.validators_on(name).map(&:kind).include?(:uniqueness)
       end

      # Returns +true+ if this attribute is the primary key of the entity.
      def primary_key?
        @model.primary_key.to_s == name.to_s
      end

      # Returns +true+ if this attribute is used as a foreign key for any
      # relationship.
      def foreign_key?
        @domain.relationships_by_entity_name(@model.name).map(&:associations).flatten.map { |associaton|
          associaton.send(Domain.foreign_key_method_name).to_sym
        }.include?(name.to_sym)
      end

      # Returns +true+ if this attribute is used for single table inheritance.
      # These attributes are typically named +type+.
      def inheritance?
        @model.inheritance_column == name
      end

      # Method allows false to be set as an attributes option when making custom graphs.
      # It rejects all attributes when called from Diagram#filtered_attributes method
      def false?
        false
      end

      # Returns +true+ if this attribute is one of the standard 'magic' Rails
      # timestamp columns, being +created_at+, +updated_at+, +created_on+ or
      # +updated_on+.
      def timestamp?
        TIMESTAMP_NAMES.include? name
      end

      def <=>(other) # @private :nodoc:
        name <=> other.name
      end

      def to_s # @private :nodoc:
        name
      end

      # Returns a description of the attribute type. If the attribute has
      # a non-standard limit or if it is mandatory, this information is included.
      #
      # Example output:
      # <tt>:integer</tt>:: integer
      # <tt>:string, :limit => 255</tt>:: string
      # <tt>:string, :limit => 128</tt>:: string (128)
      # <tt>:decimal, :precision => 5, :scale => 2/tt>:: decimal (5,2)
      # <tt>:boolean, :null => false</tt>:: boolean *
      def type_description
        type.to_s.dup.tap do |desc|
          desc << " #{limit_description}" if limit_description
          desc << " ∗" if mandatory? && !primary_key? # Add a hair space + low asterisk (Unicode characters)
          desc << " U" if unique? && !primary_key? && !foreign_key? # Add U if unique but non-key
          desc << " PK" if primary_key?
          desc << " FK" if foreign_key?
        end
      end

      # Returns any non-standard limit for this attribute. If a column has no
      # limit or uses a default database limit, this method returns +nil+.
      def limit
        return if native_type == 'geometry' || native_type == 'geography'
        return column.limit.to_i if column.limit != native_type[:limit] and column.limit.respond_to?(:to_i)
        column.precision.to_i if column.precision != native_type[:precision] and column.precision.respond_to?(:to_i)
      end

      # Returns any non-standard scale for this attribute (decimal types only).
      def scale
        return column.scale.to_i if column.scale != native_type[:scale] and column.scale.respond_to?(:to_i)
        0 if column.precision
      end

      # Returns a string that describes the limit for this attribute, such as
      # +(128)+, or +(5,2)+ for decimal types. Returns nil if no non-standard
      # limit was set.
      def limit_description # @private :nodoc:
        return "(#{limit},#{scale})" if limit and scale
        return "(#{limit})" if limit
      end

      private

      def native_type
        @model.connection.native_database_types[type] or {}
      end
    end
  end
end
