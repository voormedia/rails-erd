class StateEvent < ActiveRecord::Base
  belongs_to :user
  belongs_to :stateful, :polymorphic => true
end
