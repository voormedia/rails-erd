class Galleon < ActiveRecord::Base
  has_many :cannons
  validates_length_of :cannons, :maximum => 36
end
