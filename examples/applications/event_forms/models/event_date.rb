class EventDate < ActiveRecord::Base
  belongs_to :event
  has_many :signups

  validates_presence_of :event, :expiry_date, :date
end
