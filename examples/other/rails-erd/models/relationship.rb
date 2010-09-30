class Relationship < ActiveRecord::Base
  belongs_to :domain
  belongs_to :source_entity, :class_name => "Entity"
  belongs_to :destination_entity, :class_name => "Entity"
  has_one :cardinality
end
