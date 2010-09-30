class Property < ActiveRecord::Base
  has_and_belongs_to_many :prototypes
  has_many :product_properties, :dependent => :destroy
  has_many :products, :through => :product_properties

  validates :name, :presentation, :presence => true
end
