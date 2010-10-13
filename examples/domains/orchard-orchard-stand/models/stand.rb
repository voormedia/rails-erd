class Stand < ActiveRecord::Base
  belongs_to :orchard
  
  validates_presence_of :orchard
end
