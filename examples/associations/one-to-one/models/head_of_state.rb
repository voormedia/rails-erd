class HeadOfState < ActiveRecord::Base
  set_table_name :heads_of_state
  belongs_to :country
  validates_presence_of :country
end
