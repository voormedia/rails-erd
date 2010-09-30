class Address < ActiveRecord::Base
  belongs_to :country
  belongs_to :state

  has_many :billing_checkouts, :foreign_key => "bill_address_id", :class_name => "Checkout"
  has_many :shipping_checkouts, :foreign_key => "ship_address_id", :class_name => "Checkout"
  has_many :shipments

  validates :firstname, :lastname, :address1, :city, :zipcode, :country, :phone, :presence => true
  validates :state, :presence => true, :if => Proc.new { |address| address.state_name.blank? && Spree::Config[:address_requires_state] }
  validates :state_name, :presence => true, :if => Proc.new { |address| address.state.blank? && Spree::Config[:address_requires_state] }
  validate :state_name_validate, :if => Proc.new { |address| address.state.blank? && Spree::Config[:address_requires_state] }
end
