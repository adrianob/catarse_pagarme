module CatarsePagarme
  class PlanDelegator
    attr_accessor :plan, :transaction
    include FeeCalculatorConcern

    def initialize(plan)
      configure_pagarme
      self.plan = plan
    end

    def create_plan
      @pagarme_plan = ::PagarMe::Plan.new({
        :name => self.plan.name,
        :days => self.plan.days,
        :amount => value_for_plan
      })

      @pagarme_plan.create

      plan.gateway_id = @pagarme_plan.id
      plan.save
    end

    def destroy_plan
      self.plan.update_attribute :enabled, false
      self.plan.subscriptions.each do |subscription|
        if subscription.gateway_id
          begin
            subscription.update_attribute :state, 'canceled'
            pagarme_subscription = PagarMe::Subscription.find_by_id(subscription.gateway_id)
            pagarme_subscription.cancel
          rescue PagarMe::PagarMeError => e
            Rails.logger.error "#{e} while canceling sub #{subscription.id}"
          end
        end
      end
    end

    def update_plan
      @pagarme_plan= ::PagarMe::Plan.find_by_id(self.plan.gateway_id)
      @pagarme_plan.name = plan.name
      @pagarme_plan.save
    end

    def fill_acquirer_data
      if plan.gateway_data.nil? || plan.gateway_data["acquirer_name"].nil? || plan.gateway_data["acquirer_tid"].nil?
        data = plan.gateway_data || {}
        plan.gateway_data = data.merge({
          acquirer_name: transaction.acquirer_name,
          acquirer_tid: transaction.tid,
          card_brand: transaction.try(:card_brand)
        })
        plan.save
      end
    end

    def value_for_plan
      (self.plan.amount * 100).to_i
    end

    protected

    def bank_account_attributes
      bank = plan.user.bank_account

      {
        bank_account: {
          bank_code: (bank.bank_code || bank.name),
          agencia: bank.agency,
          agencia_dv: bank.agency_digit,
          conta: bank.account,
          conta_dv: bank.account_digit,
          legal_name: bank.owner_name,
          document_number: bank.owner_document
        }
      }
    end

    def configure_pagarme
      ::PagarMe.api_key = CatarsePagarme.configuration.api_key
    end
  end
end

