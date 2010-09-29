class SpellMastery < ActiveRecord::Base
  belongs_to :wizard
  belongs_to :spell
  validates_presence_of :wizard, :spell
end
