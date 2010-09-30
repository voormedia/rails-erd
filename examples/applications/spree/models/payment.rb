class Payment < ActiveRecord::Base
  belongs_to :order
  belongs_to :source, :polymorphic => true
  belongs_to :payment_method
  has_many :transactions
  has_many :offsets, :class_name => 'Payment', :foreign_key => 'source_id', :conditions => "source_type = 'Payment' AND amount < 0"

  validates :payment_method, :presence => true, :if => Proc.new { |payable| payable.is_a? Checkout }
end
