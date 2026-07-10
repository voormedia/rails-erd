# frozen_string_literal: true

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
  # exclude_attributes:: Hides attributes on a per-model basis, without affecting
  #                      other models. Accepts a hash that maps model names to
  #                      either +true+ (hide all attributes for that model) or a
  #                      list of attribute names to hide. From the command line it
  #                      can also be given as a comma separated string where each
  #                      entry is either +Model+ (hide all attributes) or
  #                      +Model.attribute+ (hide a single attribute), for example
  #                      <tt>exclude_attributes="BigTable,User.password_digest"</tt>.
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

      # Canonicalises the +exclude_attributes+ option into a hash that maps
      # model names (as strings) to either +true+ (hide all attributes) or an
      # array of attribute names to hide. Accepts several input shapes:
      #
      #   * a hash, e.g. <tt>{ "BigTable" => true, "User" => ["password_digest"] }</tt>
      #     (values may be +true+/+"all"+ to hide every attribute, +false+/+nil+
      #     to hide none, or a comma separated string / array of names);
      #   * a string or array of <tt>Model</tt> / <tt>Model.attribute</tt>
      #     entries, e.g. <tt>"BigTable,User.password_digest"</tt>.
      def normalize_exclude_attributes(value)
        return {} if value.nil? || value == false

        if value.is_a?(Hash)
          value.each_with_object({}) do |(model, attrs), result|
            result[model.to_s] = normalize_exclude_attribute_value(attrs)
          end
        else
          entries = Array(value).flat_map { |entry| entry.to_s.split(",") }
          entries.each_with_object({}) do |entry, result|
            model, attribute = entry.split(".", 2)
            model = model.to_s.strip
            next if model.empty?

            if attribute.nil?
              result[model] = true
            elsif result[model] != true
              (result[model] ||= []) << attribute.strip
            end
          end
        end
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

      def normalize_exclude_attribute_value(attrs)
        case attrs
        when true then true
        when false, nil then []
        when "all", :all, "true" then true
        else
          Array(attrs).flat_map { |attr| attr.to_s.split(",") }.map(&:strip).reject(&:empty?)
        end
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
        depth = options.only_recursion_depth.to_s.to_i
        # Ensure options[:only] is an array (CLI may pass a single string)
        options[:only] = [options[:only]].flatten
        options[:only].dup.each do |class_name|
          options[:only] += recurse_into_relationships(@domain.entity_by_name(class_name), depth)
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
        excluded_by_filter?(entity) or
        !options.inheritance && entity.specialized? or
        !options.polymorphism && entity.generalized? or
        !options.disconnected && entity.disconnected?
      }.compact.tap do |entities|
        raise "No entities found; create your models first!" if entities.empty?
      end
    end

    def filtered_relationships
      @domain.relationships.reject { |relationship|
        (!options.indirect && relationship.indirect?) ||
          # Drop relationships to a model removed by :only/:exclude, otherwise the filtered-out
          # model leaks back in: Graphviz skips such edges implicitly (it only draws an edge when
          # both nodes exist) but Mermaid emits every relationship and renders any named entity.
          excluded_by_filter?(relationship.source) ||
          excluded_by_filter?(relationship.destination)
      }
    end

    # Whether the entity was removed from the diagram by the :only or :exclude option.
    # Used to filter both entities and the relationships that touch them.
    #
    def excluded_by_filter?(entity)
      name = entity.name.to_s

      if options.exclude.present?
        patterns = [options.exclude].flatten
        return true if patterns.any? { |pattern| matches_pattern?(pattern, name) }
      end

      if options[:only].present? && entity.model
        patterns = [options[:only]].flatten
        return true unless patterns.any? { |pattern| matches_pattern?(pattern, name) }
      end

      false
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

    def filtered_specializations
      @domain.specializations.reject { |specialization|
        !options.inheritance && specialization.inheritance? or
        !options.polymorphism && specialization.polymorphic? or
        # Drop specializations whose generalized or specialized entity is not
        # part of the rendered domain (e.g. an abstract parent whose child model
        # has no table). These resolve to a Null entity with a blank name and
        # would otherwise produce an edge to a nameless entity (invalid output).
        specialization.generalized.name.to_s.empty? or
        specialization.specialized.name.to_s.empty?
      }
    end

    def filtered_attributes(entity)
      excluded = excluded_attributes_for(entity)
      return [] if excluded == :all

      entity.attributes.select { |attribute|
        # Hide attributes excluded for this specific model.
        next false if excluded.include?(attribute.name)
        # Hide every attribute when the :attributes option is off or the entity
        # is specialized (its attributes are shown on the parent instead).
        next false if !options.attributes || entity.specialized?
        # Otherwise keep only attributes matching the requested :attributes types.
        [*options.attributes].any? { |type| attribute.send(:"#{type.to_s.chomp('s')}?") }
      }
    end

    # Returns the attribute exclusions configured for the given entity through
    # the +exclude_attributes+ option. Returns +:all+ when every attribute
    # should be hidden, or an array of attribute names otherwise.
    def excluded_attributes_for(entity)
      spec = normalized_exclude_attributes[entity.name]
      return :all if spec == true
      Array(spec)
    end

    def normalized_exclude_attributes
      @normalized_exclude_attributes ||= self.class.normalize_exclude_attributes(options.exclude_attributes)
    end

    def warn(message)
      puts "Warning: #{message}" if options.warn
    end
  end
end
