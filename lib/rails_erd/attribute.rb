# -*- encoding: utf-8
module RailsERD
  class Attribute
    TIMESTAMP_NAMES = %w{created_at created_on updated_at updated_on} #:nodoc:

    class << self
      def from_model(domain, model) #:nodoc:
        model.arel_table.columns.collect { |column| Attribute.new(domain, model, column) }.sort
      end
    end

    attr_reader :column #:nodoc:
  
    def initialize(domain, model, column)
      @domain, @model, @column = domain, model, column
    end
    
    def name
      column.name
    end
    
    def type
      column.type
    end
    
    def mandatory?
      !column.null or @model.validators_on(name).map(&:kind).include?(:presence)
    end
    
    def primary_key?
      @model.arel_table.primary_key == name
    end
  
    def foreign_key?
      @domain.relationships_for(@model).map(&:associations).flatten.map(&:primary_key_name).include?(name)
    end
    
    def timestamp?
      TIMESTAMP_NAMES.include? name
    end
    
    def <=>(other) #:nodoc:
      name <=> other.name
    end
    
    def inspect #:nodoc:
      "#<#{self.class.name}:0x%.14x @column=#{name.inspect} @type=#{type.inspect}>" % (object_id << 1)
    end
  
    def to_s #:nodoc:
      name
    end
  
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
