module RailsERD
  class Relationship
    class Cardinality
      CARDINALITY_NAMES = %w{one_to_one one_to_many many_to_many} # @private :nodoc:
      ORDER = {} # @private :nodoc:

      class << self
        # Returns the cardinality as a symbol.
        attr_reader :type
        
        def from_macro(macro) # @private :nodoc:
          case macro
          when :has_and_belongs_to_many then ManyToMany
          when :has_many then OneToMany
          when :has_one then OneToOne
          end
        end
        
        def <=>(other) # @private :nodoc:
          ORDER[self] <=> ORDER[other]
        end
        
        CARDINALITY_NAMES.each do |cardinality|
          define_method :"#{cardinality}?" do
            type == cardinality
          end
        end
      end
      
      CARDINALITY_NAMES.each_with_index do |cardinality, i|
        klass = Cardinality.const_set cardinality.camelize.to_sym, Class.new(Cardinality) { @type = cardinality }
        ORDER[klass] = i
      end
    end
  end
end
