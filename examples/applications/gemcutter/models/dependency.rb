class Dependency < ActiveRecord::Base
  belongs_to :rubygem
  belongs_to :version

  validates_presence_of  :requirements
end
