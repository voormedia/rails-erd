class Resource < ActiveRecord::Base
  validates_uniqueness_of :filename
  belongs_to :article
end
