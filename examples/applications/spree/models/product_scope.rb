class ProductScope < ActiveRecord::Base
  belongs_to :product_group

  validate :check_validity_of_scope
end
