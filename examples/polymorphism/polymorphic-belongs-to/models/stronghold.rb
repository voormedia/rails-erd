class Stronghold < ActiveRecord::Base
  has_many :cannons, :as => :defensible
end
