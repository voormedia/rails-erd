class Ownership < ActiveRecord::Base
  belongs_to :rubygem
  belongs_to :user

  validates_uniqueness_of :user_id, :scope => :rubygem_id
end
