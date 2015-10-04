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
      plan.save!
    end

    def update_plan
      return
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

    # Transfer plan amount to payer bank account via transfers API
    # Params:
    # +authorized_by+:: +User+ object that authorize this transfer
    def transfer_funds(authorized_by)
      raise 'must be admin to perform this action' unless authorized_by.try(:admin?)

      bank_account = PagarMe::BankAccount.new(bank_account_attributes.delete(:bank_account))
      bank_account.create
      raise "unable to create an bank account" unless bank_account.id.present?

      transfer = PagarMe::Transfer.new({
        bank_account_id: bank_account.id,
        amount: value_for_plan
      })
      transfer.create

      plan.plan_transfers.create!({
        user: authorized_by,
        transfer_id: transfer.id,
        transfer_data: transfer.to_json
      })
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

