class ReturnAuthorization < ActiveRecord::Base
  belongs_to :order
  has_many :inventory_units

  validates :order, :presence => true
  validates :amount, :numericality => true
  validate :must_have_shipped_units
end
