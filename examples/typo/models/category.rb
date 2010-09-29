class Category < ActiveRecord::Base
  has_many :categorizations
  has_many :articles,
    :through => :categorizations,
    :order   => "published_at DESC, created_at DESC"

  validates_presence_of :name
  validates_uniqueness_of :name, :on => :create
end
