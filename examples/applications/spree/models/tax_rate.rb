class TaxRate < ActiveRecord::Base
  belongs_to :zone
  belongs_to :tax_category

  validates :amount, :presence => true, :numericality => true
end
