class Adjustment < ActiveRecord::Base
  belongs_to :order
  belongs_to :source, :polymorphic => true
  belongs_to :originator, :polymorphic => true

  validates :label, :presence => true
  validates :amount, :numericality => true
end
