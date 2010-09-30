class ShippingMethod < ActiveRecord::Base
  belongs_to :zone
  has_many :shipments
end
