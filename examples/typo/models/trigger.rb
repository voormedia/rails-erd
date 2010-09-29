class Trigger < ActiveRecord::Base
  belongs_to :pending_item, :polymorphic => true
end
