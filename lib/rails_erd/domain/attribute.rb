# encoding: utf-8
module RailsERD
  class Domain
    # Describes an entity's attribute. Attributes correspond directly to
    # database columns.
    class Attribute
      TIMESTAMP_NAMES = %w{created_at created_on updated_at updated_on} # @private :nodoc:

      class << self
        def from_model(domain, model) # @private :nodoc:
          model.columns.collect { |column| Attribute.new(domain, model, column) }.sort
        end
      end
      
      extend Inspectable
      inspect_with :name, :type

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
        column.type
      end
    
      # Returns +true+ if this attribute has no special meaning, that is, if it
      # is not a primary key, foreign key, or timestamp.
      def regular?
        !primary_key? and !foreign_key? and !timestamp?
      end
    
      # Returns +true+ if this attribute is mandatory. Mandatory attributes
      # either have a presence validation (+validates_presence_of+), or have a
      # <tt>NOT NULL</tt> database constraint.
      def mandatory?
        !column.null or @model.validators_on(name).map(&:kind).include?(:presence)
      end
    
      # Returns +true+ if this attribute is the primary key of the entity.
      def primary_key?
        column.primary
      end
  
      # Returns +true+ if this attribute is used as a foreign key for any
      # relationship.
      def foreign_key?
        @domain.relationships_for(@model).map(&:associations).flatten.map(&:primary_key_name).include?(name)
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
      # <tt>:boolean, :null => false</tt>:: boolean *
      def type_description
        type.to_s.tap do |desc|
          desc << " (#{limit})" if limit
          desc << " ∗" if mandatory? # Add a hair space + low asterisk (Unicode characters).
        end
      end
    
      # Returns any non-standard limit for this attribute. If a column has no
      # limit or uses a default database limit, this method returns +nil+.
      def limit
        column.limit if column.limit != @model.connection.native_database_types[type][:limit]
      end
    end
  end
end
