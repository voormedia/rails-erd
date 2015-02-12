class OptionType < ActiveRecord::Base
  if ActiveRecord::VERSION::MAJOR >= 4
    has_many :option_values, lambda { order(:position) }, :dependent => :destroy
  else
    has_many :option_values, :order => :position, :dependent => :destroy
  end
  has_many :product_option_types, :dependent => :destroy
  has_and_belongs_to_many :prototypes
  validates :name, :presentation, :presence => true
end
