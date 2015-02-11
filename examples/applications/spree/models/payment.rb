class Payment < ActiveRecord::Base
  belongs_to :order
  belongs_to :source, :polymorphic => true
  belongs_to :payment_method
  has_many :transactions
  if ActiveRecord::VERSION::MAJOR >= 4
    has_many :offsets, lambda { where("source_type = 'Payment' AND amount < 0") }, :class_name => 'Payment', :foreign_key => 'source_id'
  else
    has_many :offsets, :class_name => 'Payment', :foreign_key => 'source_id', :conditions => "source_type = 'Payment' AND amount < 0"
  end

  validates :payment_method, :presence => true, :if => Proc.new { |payable| payable.is_a? Checkout }
end
