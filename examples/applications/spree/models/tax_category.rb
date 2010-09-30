class TaxCategory < ActiveRecord::Base
  has_many :tax_rates

  validates :name, :presence => true, :uniqueness => true
end
