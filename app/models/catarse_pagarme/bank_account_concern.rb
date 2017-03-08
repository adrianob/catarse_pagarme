module CatarsePagarme::BankAccountConcern
  extend ActiveSupport::Concern

  included do

    validate :must_be_valid_on_pagarme

    def must_be_valid_on_pagarme
      pagarme_errors.each do |p_error|
        _attr = attributes_parsed_from_pagarme[p_error.parameter_name.to_sym]
        errors.add(_attr, :invalid)
      end
    end

    private

    def pagarme_errors
      configure_pagarme
      bank_account = ::PagarMe::BankAccount.new(attributes_parsed_to_pagarme)

      begin
        bank_account.create

        []
      rescue Exception => e
        e.errors
      end
    end

    def attributes_parsed_to_pagarme
      pagarme_params = {
        bank_code: self.bank.try(:code),
        agencia: self.agency,
        conta: self.account,
        conta_dv: self.account_digit,
        legal_name: self.user.name[0..29],
        document_number: self.user.cpf,
        type: self.account_type
      }
      pagarme_params[:agencia_dv] = self.agency_digit unless self.agency_digit.blank?
      pagarme_params
    end

    def attributes_parsed_from_pagarme
      {
        bank_code: :bank,
        agencia: :agency,
        agencia_dv: :agency_digit,
        conta: :account,
        conta_dv: :account_digit,
        legal_name: :owner_name,
        document_number: :owner_document,
        type: :account_type
      }
    end

    def configure_pagarme
      ::PagarMe.api_key = CatarsePagarme.configuration.api_key
    end
  end
end
