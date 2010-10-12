class Group < ActiveRecord::Base
  belongs_to :organization
  belongs_to :stylesheet
  belongs_to :form
  has_many :events
  has_many :event_dates, :through => :events, :source => :dates

  validates_presence_of :organization, :title, :url_slug, :form, :stylesheet
end
