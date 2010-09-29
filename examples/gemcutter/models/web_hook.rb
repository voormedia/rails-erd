class WebHook < ActiveRecord::Base
  belongs_to :user
  belongs_to :rubygem
end
