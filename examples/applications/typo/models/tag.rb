class Tag < ActiveRecord::Base
  if ActiveRecord::VERSION::MAJOR >= 4
    has_and_belongs_to_many :articles, lambda { order(:created_at => :desc) }
  else
    has_and_belongs_to_many :articles, :order => 'created_at DESC'
  end
  validates_uniqueness_of :name
end
