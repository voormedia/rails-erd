class Tree < ActiveRecord::Base
  belongs_to :orchard
  belongs_to :species

  validates_presence_of :orchard
  validates_presence_of :species
end
