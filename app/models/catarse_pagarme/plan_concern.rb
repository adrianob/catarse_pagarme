module CatarsePagarme::PlanConcern
  extend ActiveSupport::Concern

  included do
    def pagarme_plan_delegator
      CatarsePagarme::PlanDelegator.new(self)
    end
  end
end

