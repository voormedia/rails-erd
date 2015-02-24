module RailsERD
  class Domain
    # Describes the specialization of an entity. Specialized entities correspond
    # to inheritance or polymorphism. In Rails, specialization is referred to
    # as single table inheritance, while generalization is referred to as
    # polymorphism or abstract classes.
    class Specialization
      class << self
        def from_models(domain, models) # @private :nodoc:
          models = polymorphic_from_models(domain, models) +
            inheritance_from_models(domain, models) +
            abstract_from_models(domain, models)
          models.sort
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

        def abstract_from_models(domain, models)
          models.select(&:abstract_class?).collect(&:descendants).flatten.collect { |model|
            new(domain, domain.entity_by_name(model.superclass.name), domain.entity_by_name(model.name))
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
        @domain = domain
        @generalized = generalized || NullGeneralized.new
        @specialized = specialized || NullSpecialization.new
      end

      def generalization?
        generalized.generalized?
      end
      alias_method :polymorphic?, :generalization?

      def specialization?
        !generalization?
      end
      alias_method :inheritance?, :specialization?

      def <=>(other) # @private :nodoc:
        (generalized.name <=> other.generalized.name).nonzero? or (specialized.name <=> other.specialized.name)
      end
    end

    class NullSpecialization
      def name
        ""
      end
      def generalized?
        false
      end
    end

    class NullGeneralized
      def name
        ""
      end
      def generalized?
        true
      end
    end
  end
end
