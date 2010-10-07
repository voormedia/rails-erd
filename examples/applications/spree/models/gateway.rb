class Gateway < PaymentMethod
  delegate_belongs_to :provider, :authorize, :purchase, :capture, :void, :credit
  validates :name, :type, :presence => true
end
