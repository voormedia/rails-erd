require "rails_erd/domain"

module RailsERD
  # This class is an abstract class that will process a domain model and
  # allows easy creation of diagrams. To implement a new diagram type, derive
  # from this class and override +process_entity+, +process_relationship+,
  # and (optionally) +save+.
  #
  # As an example, a diagram class that generates code that can be used with
  # yUML (https://yuml.me) can be as simple as:
  #
  #   require "rails_erd/diagram"
  #
  #   class YumlDiagram < RailsERD::Diagram
  #     setup { @edges = [] }
  #
  #     each_relationship do |relationship|
  #       return if relationship.indirect?
  #
  #       arrow = case
  #       when relationship.one_to_one?   then "1-1>"
  #       when relationship.one_to_many?  then "1-*>"
  #       when relationship.many_to_many? then "*-*>"
  #       end
  #
  #       @edges << "[#{relationship.source}] #{arrow} [#{relationship.destination}]"
  #     end
  #
  #     save { @edges * "\n" }
  #   end
  #
  # Then, to generate the diagram (example based on the domain model of Gemcutter):
  #
  #   YumlDiagram.create
  #   #=> "[Rubygem] 1-*> [Ownership]
  #   #    [Rubygem] 1-*> [Subscription]
  #   #    [Rubygem] 1-*> [Version]
  #   #    [Rubygem] 1-1> [Linkset]
  #   #    [Rubygem] 1-*> [Dependency]
  #   #    [Version] 1-*> [Dependency]
  #   #    [User] 1-*> [Ownership]
  #   #    [User] 1-*> [Subscription]
  #   #    [User] 1-*> [WebHook]"
  #
  # For another example implementation, see Diagram::Graphviz, which is the
  # default (and currently only) diagram type that is used by Rails ERD.
  #
  # === Options
  #
  # The following options are available and will by automatically used by any
  # diagram generator inheriting from this class.
  #
  # attributes:: Selects which attributes to display. Can be any combination of
  #              +:content+, +:primary_keys+, +:foreign_keys+, +:timestamps+, or
  #              +:inheritance+.
  # disconnected:: Set to +false+ to exclude entities that are not connected to other
  #                entities. Defaults to +false+.
  # indirect:: Set to +false+ to exclude relationships that are indirect.
  #            Indirect relationships are defined in Active Record with
  #            <tt>has_many :through</tt> associations.
  # inheritance:: Set to +true+ to include specializations, which correspond to
  #               Rails single table inheritance.
  # polymorphism:: Set to +true+ to include generalizations, which correspond to
  #                Rails polymorphic associations.
  # warn:: When set to +false+, no warnings are printed to the
  #        command line while processing the domain model. Defaults
  #        to +true+.
  class Diagram
    class << self
      # Generates a new domain model based on all <tt>ActiveRecord::Base</tt>
      # subclasses, and creates a new diagram. Use the given options for both
      # the domain generation and the diagram generation.
      def create(options = {})
        new(Domain.generate(options), options).create
      end

      protected

      def setup(&block)
        callbacks[:setup] = block
      end

      def each_entity(&block)
        callbacks[:each_entity] = block
      end

      def each_relationship(&block)
        callbacks[:each_relationship] = block
      end

      def each_specialization(&block)
        callbacks[:each_specialization] = block
      end

      def save(&block)
        callbacks[:save] = block
      end

      private

      def callbacks
        @callbacks ||= Hash.new { proc {} }
      end
    end

    # The options that are used to create this diagram.
    attr_reader :options

    # The domain that this diagram represents.
    attr_reader :domain

    # Create a new diagram based on the given domain.
    def initialize(domain, options = {})
      @domain, @options = domain, RailsERD.options.merge(options)
    end

    # Generates and saves the diagram, returning the result of +save+.
    def create
      generate
      save
    end

    # Generates the diagram, but does not save the output. It is called
    # internally by Diagram#create.
    def generate
      instance_eval(&callbacks[:setup])
      if options.only_recursion_depth.present?
        depth = options.only_recursion_depth.to_i
        options[:only].dup.each do |class_name|
          options[:only]+= recurse_into_relationships(@domain.entity_by_name(class_name), depth)
        end
        options[:only].uniq!
      end

      filtered_entities.each do |entity|
        instance_exec entity, filtered_attributes(entity), &callbacks[:each_entity]
      end

      filtered_specializations.each do |specialization|
        instance_exec specialization, &callbacks[:each_specialization]
      end

      filtered_relationships.each do |relationship|
        instance_exec relationship, &callbacks[:each_relationship]
      end
    end

    def recurse_into_relationships(entity, max_level, current_level = 0)
      return [] unless entity
      return [] if max_level == current_level

      relationships = entity.relationships.reject{|r| r.indirect? || r.recursive?}

      relationships.map do |relationship|
        other_entitiy = if relationship.source == entity
                          relationship.destination
                        else
                          relationship.source
                        end
        if other_entitiy and !other_entitiy.generalized?
          [other_entitiy.name] + recurse_into_relationships(other_entitiy, max_level, current_level + 1)
        else
          []
        end
      end.flatten.uniq
    end

    def save
      instance_eval(&callbacks[:save])
    end

    private

    def callbacks
      @callbacks ||= self.class.send(:callbacks)
    end

    def filtered_entities
      @domain.entities.reject { |entity|
        options.exclude.present? && entity.model && [options.exclude].flatten.map(&:to_sym).include?(entity.name.to_sym) or
        options[:only].present? && entity.model && ![options[:only]].flatten.map(&:to_sym).include?(entity.name.to_sym) or
        !options.inheritance && entity.specialized? or
        !options.polymorphism && entity.generalized? or
        !options.disconnected && entity.disconnected?
      }.compact.tap do |entities|
        raise "No entities found; create your models first!" if entities.empty?
      end
    end

    def filtered_relationships
      @domain.relationships.reject { |relationship|
        !options.indirect && relationship.indirect?
      }
    end

    def filtered_specializations
      @domain.specializations.reject { |specialization|
        !options.inheritance && specialization.inheritance? or
        !options.polymorphism && specialization.polymorphic?
      }
    end

    def filtered_attributes(entity)
      entity.attributes.reject { |attribute|
        # Select attributes that satisfy the conditions in the :attributes option.
        !options.attributes or entity.specialized? or
        [*options.attributes].none? { |type| attribute.send(:"#{type.to_s.chomp('s')}?") }
      }
    end

    def warn(message)
      puts "Warning: #{message}" if options.warn
    end
  end
end
