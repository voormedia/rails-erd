class Order < ActiveRecord::Base
  belongs_to :user
  belongs_to :bill_address, :foreign_key => "bill_address_id", :class_name => "Address"
  belongs_to :ship_address, :foreign_key => "ship_address_id", :class_name => "Address"
  belongs_to :shipping_method
  has_many :state_events, :as => :stateful
  has_many :line_items, :dependent => :destroy
  has_many :inventory_units
  has_many :payments, :dependent => :destroy
  has_many :shipments, :dependent => :destroy
  has_many :return_authorizations, :dependent => :destroy
  has_many :adjustments, :dependent => :destroy

  validates_presence_of :email, :if => :require_email
end
