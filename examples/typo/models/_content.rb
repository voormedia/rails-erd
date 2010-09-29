class Content < ActiveRecord::Base
  belongs_to :text_filter
  has_many :notifications, :foreign_key => 'content_id'
  has_many :notify_users, :through => :notifications,
    :source => 'notify_user',
    :uniq => true
  has_many :triggers, :as => :pending_item, :dependent => :delete_all
end
