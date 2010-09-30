class BillingIntegration < PaymentMethod
  validates :name, :presence => true
end
