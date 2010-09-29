class Redirect < ActiveRecord::Base
  validates_uniqueness_of :from_path
end
