class Calculator < ActiveRecord::Base
  belongs_to :calculable, :polymorphic => true
end
