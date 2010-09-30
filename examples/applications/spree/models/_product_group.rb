class ProductGroup < ActiveRecord::Base
  validates :name, :presence => true
  validates_associated :product_scopes

  has_and_belongs_to_many :cached_products, :class_name => "Product"
  has_many :product_scopes
end
