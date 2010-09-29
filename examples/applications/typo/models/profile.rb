class Profile < ActiveRecord::Base
  validates_uniqueness_of :label
end
