class ProductProperty < ActiveRecord::Base
  belongs_to :product
  belongs_to :property

  validates :property, :presence => true
end
