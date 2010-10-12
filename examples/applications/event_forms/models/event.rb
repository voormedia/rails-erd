class Event < ActiveRecord::Base
  belongs_to :group
  has_many :dates, :class_name => "EventDate", :foreign_key => "event_id"

  validates_presence_of :group, :title
end
