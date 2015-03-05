# This is an experiment at using Rails ERD reflection to reconstruct the
# domain model in Active Record itself. It does not support specializations or
# indirect relationships.
require "rails_erd/diagram"

class Identity < RailsERD::Diagram
  setup do
    @class_defintions = {}
  end

  each_entity do |entity, attributes|
    @class_defintions[entity.name] = []
  end

  each_relationship do |relationship|
    unless relationship.indirect?
      @class_defintions[relationship.source.name] << association_macro(relationship)
      @class_defintions[relationship.destination.name] << reverse_association_macro(relationship)
    end
  end

  save do
    @class_defintions.each do |klass, lines|
      puts "class #{klass} < ActiveRecord::Base"
      lines.each do |line|
        puts "  #{line}"
      end
      puts "end"
    end
  end

  private

  def association_macro(relationship)
    name = relationship.destination.name.underscore
    case
    when relationship.to_one?       then "has_one :#{name}"
    when relationship.many_to_many? then "has_and_belongs_to_many :#{name.pluralize}"
    when relationship.to_many?      then "has_many :#{name.pluralize}"
    end
  end

  def reverse_association_macro(relationship)
    name = relationship.source.name.underscore
    case
    when relationship.many_to?      then "has_and_belongs_to_many :#{name.pluralize}"
    when relationship.one_to?       then "belongs_to :#{name}"
    end
  end
end
