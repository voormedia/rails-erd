class User < ActiveRecord::Base
  has_and_belongs_to_many :roles
  if ActiveRecord::VERSION::MAJOR >= 4
    has_many :plugins, lambda { order(:position => :asc) }, :class_name => "UserPlugin", :dependent => :destroy
  else
    has_many :plugins, :class_name => "UserPlugin", :order => "position ASC", :dependent => :destroy
  end
  has_friendly_id :login, :use_slug => true
end
