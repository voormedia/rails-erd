module RailsERD
  class Domain
    # Describes the specialization of an entity. Specialized entites correspond
    # to inheritance. In Rails, specialization is referred to as single table
    # inheritance.
    class Specialization
      class << self
        def from_models(domain, models) # @private :nodoc:
          (inheritance_from_models(domain, models) + polymorphic_from_models(domain, models)).sort
        end
        
        private
        
        def polymorphic_from_models(domain, models)
          models.collect(&:reflect_on_all_associations).flatten.collect { |association|
            [association.options[:as].to_s.classify, association.active_record.name] if association.options[:as]
          }.compact.uniq.collect { |names|
            new(domain, domain.entity_by_name(names.first), domain.entity_by_name(names.last))
          }
        end
        
        def inheritance_from_models(domain, models)
          models.reject(&:descends_from_active_record?).collect { |model|
            new(domain, domain.entity_by_name(model.base_class.name), domain.entity_by_name(model.name))
          }
        end
      end
      
      extend Inspectable
      inspection_attributes :generalized, :specialized

      # The domain in which this specialization is defined.
      attr_reader :domain

      # The source entity.
      attr_reader :generalized
    
      # The destination entity.
      attr_reader :specialized
      
      def initialize(domain, generalized, specialized) # @private :nodoc:
        @domain, @generalized, @specialized = domain, generalized, specialized
      end
      
      def inheritance?
        !polymorphic?
      end
      
      def polymorphic?
        generalized.generalized?
      end

      def <=>(other) # @private :nodoc:
        (generalized.name <=> other.generalized.name).nonzero? or (specialized.name <=> other.specialized.name)
      end
    end
  end
end
