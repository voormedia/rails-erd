class Entity < ActiveRecord::Base
  belongs_to :domain
  has_many :properties
  has_many :outgoing_relationships, :class_name => "Relationship", :foreign_key => :source_entity_id
  has_many :incoming_relationships, :class_name => "Relationship", :foreign_key => :destination_entity_id
  validates_presence_of :properties
end
