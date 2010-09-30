class Product < ActiveRecord::Base
  has_many :product_option_types, :dependent => :destroy
  has_many :option_types, :through => :product_option_types
  has_many :product_properties, :dependent => :destroy
  has_many :properties, :through => :product_properties
  has_many :images, :as => :viewable, :order => :position, :dependent => :destroy
  has_and_belongs_to_many :product_groups
  belongs_to :tax_category
  has_and_belongs_to_many :taxons
  belongs_to :shipping_category
  has_one :master,
    :class_name => 'Variant',
    :conditions => ["variants.is_master = ? AND variants.deleted_at IS NULL", true]
  delegate_belongs_to :master, :sku, :price, :weight, :height, :width, :depth, :is_master
  delegate_belongs_to :master, :cost_price if Variant.table_exists? && Variant.column_names.include?("cost_price")
  has_many :variants,
    :conditions => ["variants.is_master = ? AND variants.deleted_at IS NULL", false]
  has_many :variants_including_master,
    :class_name => 'Variant',
    :conditions => ["variants.deleted_at IS NULL"],
    :dependent => :destroy

  validates :name, :price, :permalink, :presence => true
end
