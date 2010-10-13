class Company < ActiveRecord::Base
  has_many :orchards

  validates_presence_of :orchards
end
