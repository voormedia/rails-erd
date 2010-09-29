class Notification < ActiveRecord::Base
  belongs_to :notify_content, :class_name => 'Content', :foreign_key => 'content_id'
  belongs_to :notify_user, :class_name => 'User', :foreign_key => 'user_id'
end
