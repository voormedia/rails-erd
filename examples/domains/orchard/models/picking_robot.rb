class PickingRobot < ActiveRecord::Base
  has_and_belongs_to_many :orchards
  
  validates_presence_of :orchards
end
