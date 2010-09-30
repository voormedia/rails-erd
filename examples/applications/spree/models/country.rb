class Country < ActiveRecord::Base
  has_many :states
  has_one :zone_member, :as => :zoneable
  has_one :zone, :through => :zone_member

  validates :name, :iso_name, :presence => true
end
