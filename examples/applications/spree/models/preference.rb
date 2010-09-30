class Preference < ActiveRecord::Base
  belongs_to  :owner, :polymorphic => true
  belongs_to  :group, :polymorphic => true
  
  validates :name, :owner_id, :owner_type, :presence => true
  validates :group_type, :presence => true, :if => :group_id?
end
