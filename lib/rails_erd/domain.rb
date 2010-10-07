require "rails_erd"
require "rails_erd/domain/attribute"
require "rails_erd/domain/entity"
require "rails_erd/domain/relationship"
require "rails_erd/domain/specialization"

module RailsERD
  # The domain describes your Rails domain model. This class is the starting
  # point to get information about your models.
  #
  # === Options
  #
  # The following options are available:
  #
  # warn:: When set to +false+, no warnings are printed to the
  #        command line while processing the domain model. Defaults
  #        to +true+.
  class Domain
    class << self
      # Generates a domain model object based on all loaded subclasses of
      # <tt>ActiveRecord::Base</tt>. Make sure your models are loaded before calling
      # this method.
      #
      # The +options+ hash allows you to override the default options. For a
      # list of available options, see RailsERD.
      def generate(options = {})
        new ActiveRecord::Base.descendants, options
      end
    end
    
    extend Inspectable
    inspect_with
    
    # The options that are used to generate this domain model.
    attr_reader :options

    # Create a new domain model object based on the given array of models.
    # The given models are assumed to be subclasses of <tt>ActiveRecord::Base</tt>.
    def initialize(models = [], options = {})
      @models, @options = models, RailsERD.options.merge(options)
    end

    # Returns the domain model name, which is the name of your Rails
    # application or +nil+ outside of Rails.
    def name
      defined? Rails and Rails.application and Rails.application.class.parent.name
    end
    
    # Returns all entities of your domain model.
    def entities
      @entities ||= Entity.from_models(self, @models)
    end
    
    # Returns all relationships in your domain model.
    def relationships
      @relationships ||= Relationship.from_associations(self, associations)
    end
    
    # Returns all specializations in your domain model.
    def specializations
      @specializations ||= Specialization.from_models(self, @models)
    end
    
    # Returns a specific entity object for the given Active Record model.
    def entity_for(model) # @private :nodoc:
      entity_mapping[model] or raise "model #{model} exists, but is not included in domain"
    end
    
    # Returns an array of relationships for the given Active Record model.
    def relationships_for(model) # @private :nodoc:
      relationships_mapping[model] or []
    end
    
    def warn(message) # @private :nodoc:
      puts "Warning: #{message}" if options.warn
    end
    
    private
    
    def entity_mapping
      @entity_mapping ||= {}.tap do |mapping|
        entities.each do |entity|
          mapping[entity.model] = entity
        end
      end
    end
    
    def relationships_mapping
      @relationships_mapping ||= {}.tap do |mapping|
        relationships.each do |relationship|
          (mapping[relationship.source.model] ||= []) << relationship
          (mapping[relationship.destination.model] ||= []) << relationship
        end
      end
    end
    
    def associations
      @associations ||= @models.collect(&:reflect_on_all_associations).flatten.select { |assoc| check_association_validity(assoc) }
    end
    
    def check_association_validity(association)
      # Raises an ActiveRecord::ActiveRecordError if the association is broken.
      association.check_validity!

      # Raises NameError if the associated class cannot be found.
      model = association.klass
      
      # Raises error if model is not in the domain.
      entity_for model
    rescue => e
      warn "Ignoring invalid association #{association_description(association)} (#{e.message})"
    end
    
    def association_description(association)
      "#{association.name.inspect} on #{association.active_record}"
    end
  end
end
