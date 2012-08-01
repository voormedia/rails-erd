class Organization < ActiveRecord::Base
  has_many :groups
  has_many :stylesheets
  has_many :forms
  has_many :events, :through => :groups

  validates_presence_of :name, :subdomain
end