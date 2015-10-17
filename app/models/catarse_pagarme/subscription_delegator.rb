module CatarsePagarme
  class SubscriptionDelegator
    attr_accessor :subscription, :transaction

    def initialize(subscription)
      configure_pagarme
      self.subscription = subscription
    end

    def change_status_by_transaction(transaction_status)
      #trialing, paid, pending_payment, unpaid, canceled, ended
      case transaction_status
      when 'paid' then
        self.subscription.pay unless self.subscription.paid?
      when 'pending_payment' then #payment is late
        self.subscription.require_payment unless self.subscription.pending_payment?
      when 'unpaid' then #past waiting_payment deadline, disable service
        self.subscription.disable unless self.subscription.unpaid?
      when 'canceled' then
        self.subscription.cancel unless self.subscription.canceled?
      end
    end

    protected

    def configure_pagarme
      ::PagarMe.api_key = CatarsePagarme.configuration.api_key
    end
  end
end


