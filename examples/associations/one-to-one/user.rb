class User < ActiveRecord::Base
  has_one :profile
end
