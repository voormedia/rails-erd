require "set"
require "rails_erd"
require "rails_erd/entity"
require "rails_erd/relationship"
require "rails_erd/relationship/cardinality"
require "rails_erd/attribute"

module RailsERD
  # The domain describes your Rails domain model. This class is the starting
  # point to get information about your models.
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
    
    attr_reader :options #:nodoc:

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
      @entities ||= entity_mapping.values.sort
    end
    
    # Returns all relationships in your domain model.
    def relationships
      @relationships ||= Relationship.from_associations(self, associations)
    end
    
    # Returns a specific entity object for the given +ActiveRecord+ model.
    def entity_for(model) #:nodoc:
      entity_mapping[model] or raise "model #{model} exists, but is not included in the domain"
    end
    
    # Returns an array of relationships for the given +ActiveRecord+ model.
    def relationships_for(model) #:nodoc:
      relationships_mapping[model] or []
    end
  
    def inspect #:nodoc:
      "#<#{self.class} {#{relationships.map { |rel| "#{rel.from} => #{rel.to}" } * ", "}}>"
    end
    
    private
    
    def entity_mapping
      @entity_mapping ||= Hash[@models.collect { |model| [model, Entity.new(self, model)] }]
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
      warn "Invalid association #{association_description(association)} (#{e.message})"
    end
    
    def warn(message)
      puts "Warning: #{message}" unless options.suppress_warnings
    end
    
    def association_description(association)
      "#{association.name.inspect} on #{association.active_record}"
    end
  end
end
