class Country < ActiveRecord::Base
  has_one :head_of_state
end
