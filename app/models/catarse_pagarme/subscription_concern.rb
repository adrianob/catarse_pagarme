module CatarsePagarme::SubscriptionConcern
  extend ActiveSupport::Concern

  included do
    def pagarme_subscription_delegator
      CatarsePagarme::SubscriptionDelegator.new(self)
    end
  end
end


