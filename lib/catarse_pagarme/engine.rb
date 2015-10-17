module CatarsePagarme
  class Engine < ::Rails::Engine
    isolate_namespace CatarsePagarme

    config.to_prepare do
      ::Payment.send(:include, CatarsePagarme::PaymentConcern)
      ::Plan.send(:include, CatarsePagarme::PlanConcern)
      ::Subscription.send(:include, CatarsePagarme::SubscriptionConcern)
    end
  end
end
