class Domain < ActiveRecord::Base
  has_many :entities
  has_many :relationships
  has_many :specializations
end
