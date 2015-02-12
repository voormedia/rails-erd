class User < ActiveRecord::Base
  if ActiveRecord::VERSION::MAJOR >= 4
    has_many :rubygems,
      lambda { where(:ownerships => { :approved => true }).order(:name => :asc) },
      :through => :ownerships
    has_many :subscribed_gems,
      lambda { order(:name => :asc) },
      :through => :subscriptions,
      :source  => :rubygem
  else
    has_many :rubygems, :through    => :ownerships,
                        :order      => "name ASC",
                        :conditions => { 'ownerships.approved' => true }
    has_many :subscribed_gems, :through => :subscriptions,
                               :source  => :rubygem,
                               :order   => "name ASC"
  end
  has_many :ownerships
  has_many :subscriptions
  has_many :web_hooks

  validates_uniqueness_of :handle, :allow_nil => true
end
