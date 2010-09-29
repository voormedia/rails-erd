class Subscription < ActiveRecord::Base
  belongs_to :rubygem
  belongs_to :user

  validates_uniqueness_of :rubygem_id, :scope => :user_id
end
