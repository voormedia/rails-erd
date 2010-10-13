class Orchard < ActiveRecord::Base
  belongs_to :company
  has_many :trees
  has_many :recent_trees, :class_name => "Tree", :order => "planted_on DESC"
  has_and_belongs_to_many :picking_robots
  has_one :stand

  validates_presence_of :trees
end
