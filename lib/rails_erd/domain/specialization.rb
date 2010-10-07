module RailsERD
  class Domain
    # Describes the specialization of an entity. Specialized entites correspond
    # to inheritance. In Rails, specialization is referred to as single-table
    # inheritance.
    class Specialization
      class << self
        def from_models(domain, models) # @private :nodoc:
          models.reject(&:descends_from_active_record?).collect { |model| new domain, model }.sort
        end
      end
      
      extend Inspectable
      inspect_with :generalized, :specialized

      # The domain in which this specialization is defined.
      attr_reader :domain

      # The source entity.
      attr_reader :generalized
    
      # The destination entity.
      attr_reader :specialized
      
      def initialize(domain, specialized_model)
        @domain = domain
        @generalized, @specialized = @domain.entity_for(specialized_model.base_class), @domain.entity_for(specialized_model)
      end

      def <=>(other) # @private :nodoc:
        (generalized.name <=> other.generalized.name).nonzero? or (specialized.name <=> other.specialized.name)
      end
    end
  end
end
