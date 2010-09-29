class Emperor < ActiveRecord::Base
  belongs_to :predecessor, :class_name => "Emperor"
  has_one :successor, :class_name => "Emperor", :foreign_key => :predecessor_id
end
