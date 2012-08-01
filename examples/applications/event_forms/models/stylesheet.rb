class Stylesheet < ActiveRecord::Base
  belongs_to :organization
  has_many :groups

  validates_presence_of :name
end
