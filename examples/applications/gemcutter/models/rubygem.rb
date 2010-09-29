class Rubygem < ActiveRecord::Base
  has_many :owners, :through => :ownerships, :source => :user
  has_many :ownerships, :dependent => :destroy
  has_many :subscribers, :through => :subscriptions, :source => :user
  has_many :subscriptions, :dependent => :destroy
  has_many :versions, :dependent => :destroy
  has_many :web_hooks, :dependent => :destroy
  has_one :linkset, :dependent => :destroy

  validates_presence_of :name
  validates_uniqueness_of :name
end
