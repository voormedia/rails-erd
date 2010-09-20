# -*- encoding: utf-8
module RailsERD
  # Describes an entity's attribute. Attributes correspond directly to
  # database columns.
  class Attribute
    TIMESTAMP_NAMES = %w{created_at created_on updated_at updated_on} # @private :nodoc:

    class << self
      def from_model(domain, model) # @private :nodoc:
        model.arel_table.columns.collect { |column| Attribute.new(domain, model, column) }.sort
      end
    end

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
    
    # Returns +true+ if this attribute is mandatory. Mandatory attributes
    # either have a presence validation (+validates_presence_of+), or have a
    # <tt>NOT NULL</tt> database constraint.
    def mandatory?
      !column.null or @model.validators_on(name).map(&:kind).include?(:presence)
    end
    
    # Returns +true+ if this attribute is the primary key of the entity.
    def primary_key?
      @model.arel_table.primary_key == name
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
    
    def inspect # @private :nodoc:
      "#<#{self.class.name}:0x%.14x @column=#{name.inspect} @type=#{type.inspect}>" % (object_id << 1)
    end
  
    def to_s # @private :nodoc:
      name
    end
  
    # Returns a short description of the attribute type. If the attribute has
    # a non-standard limit or if it is mandatory, this information is included.
    #
    # Example output:
    # <tt>:integer</tt>:: int
    # <tt>:string, :limit => 255</tt>:: str
    # <tt>:string, :limit => 128</tt>:: str (128)
    # <tt>:boolean, :null => false</tt>:: bool *
    def type_description
      case type
      when :integer       then "int"
      when :float         then "float"
      when :decimal       then "dec"
      when :datetime      then "datetime"
      when :date          then "date"
      when :timestamp     then "timest"
      when :time          then "time"
      when :text          then "txt"
      when :string        then "str"
      when :binary        then "blob"
      when :boolean       then "bool"
      else type.to_s
      end.tap do |desc|
        desc << " (#{column.limit})" if column.limit != @model.connection.native_database_types[type][:limit]
        desc << " ∗" if mandatory? # Add a hair space + low asterisk (Unicode characters).
      end
    end
  end
end
