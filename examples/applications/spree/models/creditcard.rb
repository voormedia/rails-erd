class Creditcard < ActiveRecord::Base
  has_many :payments, :as => :source

  validates :month, :year, :numericality => { :only_integer => true }
  validates :number, :presence => true, :unless => :has_payment_profile?, :on => :create
  validates :verification_value, :presence => true, :unless => :has_payment_profile?, :on => :create
end
