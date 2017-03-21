# Extracted from https://github.com/eric/friendly_id
class ActiveRecord::Base
  def self.has_friendly_id(column, options = {})
    if options[:use_slug]
      if ActiveRecord::VERSION::MAJOR >= 4
        has_many :slugs, lambda { order(:id => :desc) }, :as => :sluggable, :dependent => :destroy
      else
        has_many :slugs, :order => 'id DESC', :as => :sluggable, :dependent => :destroy, :readonly => true
      end
    end
  end
end
