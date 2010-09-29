class User < ActiveRecord::Base
  has_and_belongs_to_many :roles
  has_many :plugins, :class_name => "UserPlugin", :order => "position ASC", :dependent => :destroy
  has_friendly_id :login, :use_slug => true
end
