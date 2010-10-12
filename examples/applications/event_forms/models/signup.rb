class Signup < ActiveRecord::Base
  belongs_to :event_date

  validates_presence_of :email
end
