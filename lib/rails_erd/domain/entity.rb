module RailsERD
  class Domain
    # Entities represent your Active Record models. Entities may be connected
    # to other entities.
    class Entity
      class << self
        def from_models(domain, models) # @private :nodoc:
          (concrete_from_models(domain, models) + abstract_from_models(domain, models)).sort
        end

        private

        def concrete_from_models(domain, models)
          models.collect { |model| new(domain, model.name, model) }
        end

        def abstract_from_models(domain, models)
          models.collect(&:reflect_on_all_associations).flatten.collect { |association|
            association.options[:as].to_s.classify if association.options[:as]
          }.flatten.compact.uniq.collect { |name| new(domain, name) }
        end
      end

      extend Inspectable
      inspection_attributes :model

      # The domain in which this entity resides.
      attr_reader :domain

      # The Active Record model that this entity corresponds to.
      attr_reader :model

      # The name of this entity. Equal to the class name of the corresponding
      # model (for concrete entities) or given name (for abstract entities).
      attr_reader :name

      def initialize(domain, name, model = nil) # @private :nodoc:
        @domain, @name, @model = domain, name, model
      end

      # Returns an array of attributes for this entity.
      def attributes
        @attributes ||= generalized? ? [] : Attribute.from_model(domain, model)
      end

      # Returns an array of all relationships that this entity has with other
      # entities in the domain model.
      def relationships
        domain.relationships_by_entity_name(name)
      end

      # Returns +true+ if this entity has any relationships with other models,
      # +false+ otherwise.
      def connected?
        relationships.any?
      end

      # Returns +true+ if this entity has no relationships with any other models,
      # +false+ otherwise. Opposite of +connected?+.
      def disconnected?
        relationships.none?
      end

      # Returns +true+ if this entity is a generalization, which does not
      # correspond with a database table. Generalized entities are either
      # models that are defined as +abstract_class+ or they are constructed
      # from polymorphic interfaces. Any +has_one+ or +has_many+ association
      # that defines a polymorphic interface with <tt>:as => :name</tt> will
      # lead to a generalized entity to be created.
      def generalized?
        !model or !!model.abstract_class?
      end

      # Returns +true+ if this entity descends from another entity, and is
      # represented in the same table as its parent. In Rails this concept is
      # referred to as single-table inheritance. In entity-relationship
      # diagrams it is called specialization.
      def specialized?
        !!model and !model.descends_from_active_record?
      end

      # Returns +true+ if this entity does not correspond directly with a
      # database table (if and only if the entity is specialized or
      # generalized).
      def virtual?
        generalized? or specialized?
      end
      alias_method :abstract?, :virtual?

      # Returns all child entities, if this is a generalized entity.
      def children
        @children ||= domain.specializations_by_entity_name(name).map(&:specialized)
      end

      def to_s # @private :nodoc:
        name
      end

      def <=>(other) # @private :nodoc:
        self.name <=> other.name
      end
    end
  end
end
