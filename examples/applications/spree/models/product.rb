class Product < ActiveRecord::Base
  has_many :product_option_types, :dependent => :destroy
  has_many :option_types, :through => :product_option_types
  has_many :product_properties, :dependent => :destroy
  has_many :properties, :through => :product_properties
  has_and_belongs_to_many :product_groups
  belongs_to :tax_category
  has_and_belongs_to_many :taxons
  belongs_to :shipping_category
  if ActiveRecord::VERSION::MAJOR >= 4
    has_many :images, lambda { order(:position) }, :as => :viewable, :dependent => :destroy
    has_one :master,
      lambda { where(["variants.is_master = ? AND variants.deleted_at IS NULL", true]) },
      :class_name => 'Variant'
    has_many :variants,
      lambda { where(["variants.is_master = ? AND variants.deleted_at IS NULL", false]) }
    has_many :variants_including_master,
      lambda { where(["variants.deleted_at IS NULL"]) },
      :class_name => 'Variant',
      :dependent => :destroy
  else
    has_many :images, :as => :viewable, :order => :position, :dependent => :destroy
    has_one :master,
      :class_name => 'Variant',
      :conditions => ["variants.is_master = ? AND variants.deleted_at IS NULL", true]
    has_many :variants,
      :conditions => ["variants.is_master = ? AND variants.deleted_at IS NULL", false]
    has_many :variants_including_master,
      :class_name => 'Variant',
      :conditions => ["variants.deleted_at IS NULL"],
      :dependent => :destroy
  end
  delegate_belongs_to :master, :sku, :price, :weight, :height, :width, :depth, :is_master
  delegate_belongs_to :master, :cost_price if Variant.table_exists? && Variant.column_names.include?("cost_price")

  validates :name, :price, :permalink, :presence => true
end
