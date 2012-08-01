class User < ActiveRecord::Base
  belongs_to :profile
  belongs_to :text_filter
  has_many :notifications, :foreign_key => 'notify_user_id'
  has_many :notify_contents, :through => :notifications,
    :source => 'notify_content',
    :uniq => true
  has_many :articles, :order => 'created_at DESC'
  has_many :published_articles,
    :class_name => 'Article',
    :conditions => { :published => true },
    :order      => "published_at DESC"

  validates_uniqueness_of :login, :on => :create
  validates_uniqueness_of :email, :on => :create
  validates_length_of :password, :within => 5..40, :if => Proc.new { |user|
    user.read_attribute('password').nil? or user.password.to_s.length > 0
  }
  validates_presence_of :login
  validates_presence_of :email
  validates_confirmation_of :password
  validates_length_of :login, :within => 3..40
end
