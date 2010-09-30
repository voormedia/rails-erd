class MailMethod < ActiveRecord::Base
  validates :environment, :presence => true
end
