module CatarsePagarme
  class BalanceTransferDelegator
    attr_accessor :balance_transfer, :transfer

    def initialize(balance_transfer)
      configure_pagarme
      self.balance_transfer = balance_transfer
    end

    def transfer_funds
      ActiveRecord::Base.transaction do
        raise "unable to create transfer, need to be authorized" if !balance_transfer.authorized?

        bank_account = PagarMe::BankAccount.new(bank_account_attributes.delete(:bank_account))
        bank_account.create
        raise "unable to create an bank account" unless bank_account.id.present?

        transfer = PagarMe::Transfer.new({
          bank_account_id: bank_account.id,
          amount: value_for_transaction
        })
        transfer.create
        raise "unable to create a transfer" unless transfer.id.present?

        balance_transfer.update_attribute(:transfer_id, transfer.id)
        balance_transfer.transition_to(:processing, transfer_data: transfer.to_hash)
        balance_transfer
      end
    end

    def bank_account_attributes
      account = balance_transfer.project.account

      {
        bank_account: {
          bank_code: (account.bank.code || account.bank.name),
          agencia: account.agency,
          agencia_dv: account.agency_digit,
          conta: account.account,
          conta_dv: account.account_digit,
          legal_name: account.owner_name,
          document_number: account.owner_document
        }
      }
    end

    def configure_pagarme
      ::PagarMe.api_key = CatarsePagarme.configuration.api_key
    end

    def value_for_transaction
      (self.balance_transfer.amount * 100).to_i
    end
  end
end
