# frozen_string_literal: true

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

      # Returns the method name to retrieve the foreign key from an
      # association reflection object.
      def foreign_key_method_name # @private :nodoc:
        @foreign_key_method_name ||= ActiveRecord::Reflection::AssociationReflection.method_defined?(:foreign_key) ? :foreign_key : :primary_key_name
      end
    end

    extend Inspectable
    inspection_attributes

    # The options that are used to generate this domain model.
    attr_reader :options

    # Create a new domain model object based on the given array of models.
    # The given models are assumed to be subclasses of <tt>ActiveRecord::Base</tt>.
    def initialize(models = [], options = {})
      @source_models, @options = models, RailsERD.options.merge(options)
    end

    # Returns the domain model name, which is the name of your Rails
    # application or +nil+ outside of Rails.
    def name
      return unless defined?(Rails) && Rails.application

      if Rails.application.class.respond_to?(:module_parent)
        Rails.application.class.module_parent.name
      else
        Rails.application.class.parent.name
      end
    end

    # Returns all entities of your domain model.
    def entities
      @entities ||= Entity.from_models(self, models)
    end

    # Returns all relationships in your domain model.
    def relationships
      @relationships ||= Relationship.from_associations(self, associations).select do |relationship|
        relationship.source && relationship.destination
      end
    end

    # Returns all specializations in your domain model.
    def specializations
      @specializations ||= Specialization.from_models(self, models)
    end

    # Returns a specific entity object for the given Active Record model.
    def entity_by_name(name) # @private :nodoc:
      entity_mapping[name]
    end

    # Returns an array of relationships for the given Active Record model.
    def relationships_by_entity_name(name) # @private :nodoc:
      relationships_mapping[name] or []
    end

    def specializations_by_entity_name(name)
      specializations_mapping[name] or []
    end

    def warn(message) # @private :nodoc:
      puts "Warning: #{message}" if options.warn
    end

    private

    def entity_mapping
      @entity_mapping ||= {}.tap do |mapping|
        entities.each do |entity|
          mapping[entity.name] = entity
        end
      end
    end

    def relationships_mapping
      @relationships_mapping ||= {}.tap do |mapping|
        relationships.each do |relationship|
          (mapping[relationship.source.name] ||= []) << relationship
          (mapping[relationship.destination.name] ||= []) << relationship
        end
      end
    end

    def specializations_mapping
      @specializations_mapping ||= {}.tap do |mapping|
        specializations.each do |specialization|
          (mapping[specialization.generalized.name] ||= []) << specialization
          (mapping[specialization.specialized.name] ||= []) << specialization
        end
      end
    end

    def models
      @models ||= @source_models
                    .reject { |model| tableless_rails_models.include?(model) }
                    .select { |model| check_model_validity(model) }
                    .reject { |model| check_habtm_model(model) }
                    .sort_by { |model| model.name.to_s }
    end

    # Returns Rails model classes defined in the app
    def rails_models
      %w(
        ActionMailbox::InboundEmail
        ActionText::EncryptedRichText
        ActionText::RichText
        ActiveStorage::Attachment
        ActiveStorage::Blob
        ActiveStorage::VariantRecord
        SolidCable::Message
        SolidCache::Entry
        SolidQueue::BlockedExecution
        SolidQueue::ClaimedExecution
        SolidQueue::Execution
        SolidQueue::FailedExecution
        SolidQueue::Job
        SolidQueue::Pause
        SolidQueue::Process
        SolidQueue::ReadyExecution
        SolidQueue::RecurringExecution
        SolidQueue::RecurringTask
        SolidQueue::ScheduledExecution
        SolidQueue::Semaphore
      ).map { |model| Object.const_get(model) rescue nil }.compact
    end

    def tableless_rails_models
      @tableless_rails_models ||= begin
        if defined? Rails
          rails_models.reject{ |model| model.table_exists? }
        else
          []
        end
      end
    end

    def associations
      @associations ||= models.collect(&:reflect_on_all_associations).flatten.select { |assoc| check_association_validity(assoc) }
    end

    def check_model_validity(model)
      if model.abstract_class? || model.table_exists?
        if model.name.nil?
          raise "is anonymous class"
        else
          true
        end
      else
        raise "table #{model.table_name} does not exist"
      end
    rescue => e
      warn "Ignoring invalid model #{model.name} (#{e.message})" unless excluded_model?(model)
    end

    def excluded_model?(model)
      return false unless options.exclude.present?

      patterns = [options.exclude].flatten
      patterns.any? { |pattern| matches_pattern?(pattern, model.name) }
    end

    # Matches a name against a pattern. Supports three pattern types:
    #
    # - Exact match: "Foo" matches only "Foo"
    # - Glob pattern: "SolidQueue::*" matches "SolidQueue::Job", etc.
    # - Regex pattern: "/^Active/" matches "ActiveRecord", "ActiveStorage::Blob"
    #
    def matches_pattern?(pattern, name)
      pattern_str = pattern.to_s

      # Regex pattern: /pattern/ or /pattern/flags
      #
      if pattern_str.start_with?("/") && pattern_str =~ %r{\A/(.+)/([imx]*)\z}
        regex_body = Regexp.last_match(1)
        flags_str = Regexp.last_match(2)
        flags = 0
        flags |= Regexp::IGNORECASE if flags_str.include?("i")
        flags |= Regexp::MULTILINE if flags_str.include?("m")
        flags |= Regexp::EXTENDED if flags_str.include?("x")
        return Regexp.new(regex_body, flags).match?(name.to_s)
      end

      # Glob pattern: contains *, ?, or [
      #
      if pattern_str.include?("*") || pattern_str.include?("?") || pattern_str.include?("[")
        return File.fnmatch?(pattern_str, name.to_s)
      end

      # Exact match (backward compatible)
      pattern_str == name.to_s
    end

    def check_association_validity(association)
      # Raises an ActiveRecord::ActiveRecordError if the association is broken.
      association.check_validity!

      if association.options[:polymorphic]
        check_polymorphic_association_validity(association)
      else
        entity_name = association.klass.name # Raises NameError if the associated class cannot be found.
        entity_by_name(entity_name) or raise "model #{entity_name} exists, but is not included in domain"
      end
    rescue => e
      warn "Ignoring invalid association #{association_description(association)} (#{e.message})" unless excluded_association?(association)
    end

    def excluded_association?(association)
      return false unless options.exclude.present?

      patterns = [options.exclude].flatten

      # Suppress warning if either the source model or target model is excluded
      source_name = association.active_record.name
      return true if patterns.any? { |pattern| matches_pattern?(pattern, source_name) }

      target_name = association.options[:polymorphic] ? association.class_name : association.klass.name
      target_name && patterns.any? { |pattern| matches_pattern?(pattern, target_name) }
    rescue NameError
      # If we can't determine the target class, the source model was already checked above
      false
    end

    def check_polymorphic_association_validity(association)
      entity_name = association.class_name
      entity = entity_by_name(entity_name)

      if entity || (entity && entity.generalized?)
        return entity
      else
        raise("polymorphic interface #{entity_name} does not exist")
      end
    end

    def association_description(association)
      "#{association.name.inspect} on #{association.active_record}"
    end

    def check_habtm_model(model)
      model.name.start_with?("HABTM_")
    end
  end
end
