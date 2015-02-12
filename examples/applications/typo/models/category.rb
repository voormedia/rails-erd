class Category < ActiveRecord::Base
  has_many :categorizations
  if ActiveRecord::VERSION::MAJOR >= 4
    has_many :articles, lambda { order(:published_at => :desc, :created_at => :desc) },
      :through => :categorizations
  else
    has_many :articles,
      :through => :categorizations,
      :order   => "published_at DESC, created_at DESC"
  end

  validates_presence_of :name
  validates_uniqueness_of :name, :on => :create
end
