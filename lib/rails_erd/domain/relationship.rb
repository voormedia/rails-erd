require "set"
require "active_support/core_ext/module/delegation"
require "rails_erd/domain/relationship/cardinality"

module RailsERD
  class Domain
    # Describes a relationship between two entities. A relationship is detected
    # based on Active Record associations. One relationship may represent more
    # than one association, however. Related associations are grouped together.
    # Associations are related if they share the same foreign key, or the same
    # join table in the case of many-to-many associations.
    class Relationship
      N = Cardinality::N

      class << self
        def from_associations(domain, associations) # @private :nodoc:
          assoc_groups = associations.group_by { |assoc| association_identity(assoc) }
          assoc_groups.collect { |_, assoc_group| new(domain, assoc_group.to_a) }
        end

        private

        def association_identity(association)
          identifier = association_identifier(association)
          Set[identifier, association_owner(association), association_target(association)]
        end

        def association_identifier(association)
          if association.macro == :has_and_belongs_to_many
            # Rails 4+ supports the join_table method, and doesn't expose it
            # as an option if it's an implicit default.
            (association.respond_to?(:join_table) && association.join_table) || association.options[:join_table]
          else
            association.options[:through] || association.send(Domain.foreign_key_method_name).to_s
          end
        end

        def association_owner(association)
          association.options[:as] ? association.options[:as].to_s.classify : association.active_record.name
        end

        def association_target(association)
          association.options[:polymorphic] ? association.class_name : association.klass.name
        end
      end

      extend Inspectable
      inspection_attributes :source, :destination

      # The domain in which this relationship is defined.
      attr_reader :domain

      # The source entity. It corresponds to the model that has defined a
      # +has_one+ or +has_many+ association with the other model.
      attr_reader :source

      # The destination entity. It corresponds to the model that has defined
      # a +belongs_to+ association with the other model.
      attr_reader :destination

      delegate :one_to_one?, :one_to_many?, :many_to_many?, :source_optional?,
        :destination_optional?, :to => :cardinality

      def initialize(domain, associations) # @private :nodoc:
        @domain = domain
        @reverse_associations, @forward_associations = partition_associations(associations)

        assoc = @forward_associations.first || @reverse_associations.first
        @source      = @domain.entity_by_name(self.class.send(:association_owner, assoc))
        @destination = @domain.entity_by_name(self.class.send(:association_target, assoc))
        @source, @destination = @destination, @source if assoc.belongs_to?
      end

      # Returns all Active Record association objects that describe this
      # relationship.
      def associations
        @forward_associations + @reverse_associations
      end

      # Returns the cardinality of this relationship.
      def cardinality
        @cardinality ||= begin
          reverse_max = any_habtm?(associations) ? N : 1
          forward_range = associations_range(@forward_associations, N)
          reverse_range = associations_range(@reverse_associations, reverse_max)
          Cardinality.new(reverse_range, forward_range)
        end
      end

      # Indicates if a relationship is indirect, that is, if it is defined
      # through other relationships. Indirect relationships are created in
      # Rails with <tt>has_many :through</tt> or <tt>has_one :through</tt>
      # association macros.
      def indirect?
        !@forward_associations.empty? and @forward_associations.all?(&:through_reflection)
      end

      # Indicates whether or not the relationship is defined by two inverse
      # associations (e.g. a +has_many+ and a corresponding +belongs_to+
      # association).
      def mutual?
        @forward_associations.any? and @reverse_associations.any?
      end

      # Indicates whether or not this relationship connects an entity with itself.
      def recursive?
        @source == @destination
      end

      # Indicates whether the destination cardinality class of this relationship
      # is equal to one. This is +true+ for one-to-one relationships only.
      def to_one?
        cardinality.cardinality_class[1] == 1
      end

      # Indicates whether the destination cardinality class of this relationship
      # is equal to infinity. This is +true+ for one-to-many or
      # many-to-many relationships only.
      def to_many?
        cardinality.cardinality_class[1] != 1
      end

      # Indicates whether the source cardinality class of this relationship
      # is equal to one. This is +true+ for one-to-one or
      # one-to-many relationships only.
      def one_to?
        cardinality.cardinality_class[0] == 1
      end

      # Indicates whether the source cardinality class of this relationship
      # is equal to infinity. This is +true+ for many-to-many relationships only.
      def many_to?
        cardinality.cardinality_class[0] != 1
      end

      # The strength of a relationship is equal to the number of associations
      # that describe it.
      def strength
        if source.generalized? then 1 else associations.size end
      end

      def <=>(other) # @private :nodoc:
        (source.name <=> other.source.name).nonzero? or (destination.name <=> other.destination.name)
      end

      private

      def partition_associations(associations)
        if any_habtm?(associations)
          # Many-to-many associations don't have a clearly defined direction.
          # We sort by name and use the first model as the source.
          source = associations.map(&:active_record).sort_by(&:name).first
          associations.partition { |association| association.active_record != source }
        else
          associations.partition(&:belongs_to?)
        end
      end

      def associations_range(associations, absolute_max)
        # The minimum of the range is the maximum value of each association
        # minimum. If there is none, it is zero by definition. The reasoning is
        # that from all associations, if only one has a required minimum, then
        # this side of the relationship has a cardinality of at least one.
        min = associations.map { |assoc| association_minimum(assoc) }.max || 0

        # The maximum of the range is the maximum value of each association
        # maximum. If there is none, it is equal to the absolute maximum. If
        # only one association has a high cardinality on this side, the
        # relationship itself has the same maximum cardinality.
        max = associations.map { |assoc| association_maximum(assoc) }.max || absolute_max

        min..max
      end

      def association_minimum(association)
        minimum = association_validators(:presence, association).any? ||
          foreign_key_required?(association) ? 1 : 0
        length_validators = association_validators(:length, association)
        length_validators.map { |v| v.options[:minimum] }.compact.max or minimum
      end

      def association_maximum(association)
        maximum = association.collection? ? N : 1
        length_validators = association_validators(:length, association)
        length_validators.map { |v| v.options[:maximum] }.compact.min or maximum
      end

      def association_validators(kind, association)
        association.active_record.validators_on(association.name).select { |v| v.kind == kind }
      end

      def any_habtm?(associations)
        associations.any? { |association| association.macro == :has_and_belongs_to_many }
      end

      def foreign_key_required?(association)
        if !association.active_record.abstract_class? and association.belongs_to?
          column = association.active_record.columns_hash[association.send(Domain.foreign_key_method_name)] and !column.null
        end
      end
    end
  end
end
