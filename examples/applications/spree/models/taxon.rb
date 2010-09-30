class Taxon < ActiveRecord::Base
  belongs_to :taxonomy
  has_and_belongs_to_many :products

  validates :name, :presence => true
end
