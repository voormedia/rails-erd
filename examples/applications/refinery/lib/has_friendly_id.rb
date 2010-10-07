# Extracted from http://github.com/eric/friendly_id
class ActiveRecord::Base
  def self.has_friendly_id(column, options = {})
    if options[:use_slug]
      has_many :slugs, :order => 'id DESC', :as => :sluggable, :dependent => :destroy, :readonly => true
    end
  end
end
