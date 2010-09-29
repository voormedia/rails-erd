class Resource < ActiveRecord::Base
  validates :file, :presence => true,
                   :length   => { :maximum => 50000000 }
end
