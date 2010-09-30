class Shipment < ActiveRecord::Base
  belongs_to :order
  belongs_to :shipping_method
  belongs_to :address
  has_many :state_events, :as => :stateful
  has_many :inventory_units

  validates :inventory_units, :presence => true, :if => :require_inventory
  validate :shipping_method
end
