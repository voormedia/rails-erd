class Barricade < ActiveRecord::Base
  has_many :soldiers, :as => :defensible
end
