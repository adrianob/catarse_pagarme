class PaymentEngines
  def self.new_payment(attributes={})
    Payment.new attributes
  end

  def self.find_contribution(id)
    Contribution.find id
  end

  def self.find_subscription(id)
    Subscription.find id
  end

  def self.find_payment filter
    Payment.where(filter).first
  end
end
