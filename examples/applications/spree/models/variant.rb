class Variant < ActiveRecord::Base
  belongs_to :product
  delegate_belongs_to :product, :name, :description, :permalink, :available_on, :tax_category_id, :shipping_category_id, :meta_description, :meta_keywords

  has_many :inventory_units
  has_many :line_items
  has_and_belongs_to_many :option_values
  if ActiveRecord::VERSION::MAJOR >= 4
    has_many :images, lambda { order(:position) }, :as => :viewable, :dependent => :destroy
  else
    has_many :images, :as => :viewable, :order => :position, :dependent => :destroy
  end

  validate :check_price
  validates :price, :presence => true
  validates :cost_price, :numericality => true, :allow_nil => true if Variant.table_exists? && Variant.column_names.include?("cost_price")
end
