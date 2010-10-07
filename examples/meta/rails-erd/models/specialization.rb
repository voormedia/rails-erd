class Specialization < ActiveRecord::Base
  belongs_to :domain
  belongs_to :generalized_entity, :class_name => "Entity"
  belongs_to :specialized_entity, :class_name => "Entity"
end
