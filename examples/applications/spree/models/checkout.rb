class Checkout < ActiveRecord::Base
  before_update :check_addresses_on_duplication, :if => "!ship_address.nil? && !bill_address.nil?"
  after_save :update_order_shipment
  before_validation :clone_billing_address, :if => "@use_billing"

  belongs_to :order
  belongs_to :bill_address, :foreign_key => "bill_address_id", :class_name => "Address"
  belongs_to :ship_address, :foreign_key => "ship_address_id", :class_name => "Address"
  belongs_to :shipping_method
  has_many :payments, :as => :payable

  validates :order_id, :shipping_method_id, :presence => true
  validates :email, :format => { :with => /\A\S+@\S+\.\S+\z/ }
end
