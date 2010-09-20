require "rails_erd/domain"

module RailsERD
  # This class is an abstract class that will process a domain model and
  # allows easy creation of diagrams. To implement a new diagram type, derive
  # from this class and override +process_entity+, +process_relationship+, 
  # and (optionally) +save+.
  #
  # As an example, a diagram class that generates code that can be used with
  # yUML (http://yuml.me) can be as simple as:
  #
  #   require "rails_erd/diagram"
  #
  #   class YumlDiagram < RailsERD::Diagram
  #     def process_relationship(rel)
  #       return if rel.indirect?
  #
  #       arrow = case
  #       when rel.cardinality.one_to_one?   then "1-1>"
  #       when rel.cardinality.one_to_many?  then "1-*>"
  #       when rel.cardinality.many_to_many? then "*-*>"
  #       end
  #
  #       instructions << "[#{rel.source}] #{arrow} [#{rel.destination}]"
  #     end
  #
  #     def save
  #       instructions * "\n"
  #     end
  #
  #     def instructions
  #       @instructions ||= []
  #     end
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
  class Diagram
    class << self
      # Generates a new domain model based on all <tt>ActiveRecord::Base</tt>
      # subclasses, and creates a new diagram. Use the given options for both
      # the domain generation and the diagram generation.
      def create(options = {})
        new(Domain.generate(options), options).create
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
      filtered_entities.each do |entity|
        process_entity entity, filtered_attributes(entity)
      end

      filtered_relationships.each do |relationship|
        process_relationship relationship
      end
    end

    # Saves the diagram. Can be overridden in subclasses to write to an output
    # file. It is called internally by Diagram#create.
    def save
    end
        
    protected

    # Process a given entity and its attributes. This method should be implemented
    # by subclasses. It is intended to add a representation of the entity to
    # the diagram. This method will be called once for each entity that should
    # be displayed, typically in alphabetic order.
    def process_entity(entity, attributes)
    end
    
    # Process a given relationship. This method should be implemented by
    # subclasses. It should add a representation of the relationship to
    # the diagram. This method will be called once for eacn relationship
    # that should be displayed.
    def process_relationship(relationship)
    end
    
    # Returns +true+ if the layout or hierarchy of the diagram should be
    # horizontally oriented.
    def horizontal?
      options.orientation == :horizontal
    end

    # Returns +true+ if the layout or hierarchy of the diagram should be
    # vertically oriented.
    def vertical?
      !horizontal?
    end
    
    private
    
    def filtered_entities
      @domain.entities.collect do |entity|
        if options.exclude_unconnected && !entity.connected?
          warn "Skipping unconnected model #{entity.name} (use exclude_unconnected=false to include)"
        else
          entity
        end
      end.compact.tap do |entities|
        raise "No (connected) entities found; create your models first!" if entities.empty?
      end
    end
    
    def filtered_relationships
      @domain.relationships
    end
    
    def filtered_attributes(entity)
      entity.attributes.reject { |attribute|
        options.exclude_primary_keys && attribute.primary_key? or
        options.exclude_foreign_keys && attribute.foreign_key? or
        options.exclude_timestamps && attribute.timestamp?
      }
    end

    def warn(message)
      puts "Warning: #{message}" unless options.suppress_warnings
    end
  end
end
