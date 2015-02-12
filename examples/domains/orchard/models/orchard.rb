class Orchard < ActiveRecord::Base
  belongs_to :company
  has_many :trees
  if ActiveRecord::VERSION::MAJOR >= 4
    has_many :recent_trees, lambda { order(:planted_on => :desc) }, :class_name => "Tree"
  else
    has_many :recent_trees, :class_name => "Tree", :order => "planted_on DESC"
  end
  has_and_belongs_to_many :picking_robots
  has_one :stand

  validates_presence_of :trees
end
