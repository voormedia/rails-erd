class Zone < ActiveRecord::Base
  has_many :zone_members
  has_many :tax_rates
  has_many :shipping_methods

  validates :name, :presence => true, :uniqueness => true
end
