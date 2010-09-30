class LineItem < ActiveRecord::Base
  belongs_to :order
  belongs_to :variant
  has_one :product, :through => :variant

  validates :variant, :presence => true
  validates :quantity, :numericality => { :only_integer => true, :message => I18n.t("validation.must_be_int") }
  validates :price, :numericality => true
end
