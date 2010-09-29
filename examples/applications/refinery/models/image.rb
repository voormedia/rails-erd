class Image < ActiveRecord::Base
  validates :image, :presence  => true,
                    :length    => { :maximum => 20000000 }
end
