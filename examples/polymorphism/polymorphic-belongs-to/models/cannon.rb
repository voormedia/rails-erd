class Cannon < ActiveRecord::Base
  belongs_to :defensible, :polymorphic => true
end
