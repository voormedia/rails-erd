class Wizard < ActiveRecord::Base
  has_many :spell_masteries
  has_many :spells, :through => :spell_masteries
  validates_presence_of :spells, :spell_masteries
end
