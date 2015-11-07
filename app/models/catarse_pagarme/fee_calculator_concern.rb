module CatarsePagarme::FeeCalculatorConcern
  extend ActiveSupport::Concern

  included do

    def get_fee(type='payment')
      @subscription_payment = (type == 'subscription')
      payment_method = @subscription_payment ? self.subscription.payment_method : self.payment.payment_method
      return nil if payment_method.blank? # We always depend on the payment_choice
      if payment_method == ::CatarsePagarme::PaymentType::SLIP || payment_method == 'boleto'
        get_slip_fee
      else
        get_card_fee
      end
    end

    protected
    def get_slip_fee
      CatarsePagarme.configuration.slip_tax.to_f
    end

    def get_card_fee
      acquirer_name = @subscription_payment ? self.subscription.gateway_data['current_transaction']['acquirer_name'] :  self.payment.gateway_data["acquirer_name"]
      return nil if acquirer_name.blank? # Here we depend on the acquirer name
      if %w(stone pagarme).include? acquirer_name
        get_stone_fee
      else
        get_cielo_fee
      end
    end

    def get_stone_fee
      if @subscription_payment
        tax_calc(stone_tax)
      else
        self.payment.installments > 1 ? tax_calc_for_installment(stone_tax) : tax_calc(stone_tax)
      end
    end

    def get_cielo_fee
      card_brand = @subscription_payment ? self.subscription.gateway_data['current_transaction']['card_brand'] : self.payment.gateway_data["card_brand"]
      return nil if card_brand.blank? # Here we depend on the card_brand
      if card_brand == 'amex'
        get_cielo_fee_for_amex
      else
        get_cielo_fee_for_non_amex
      end
    end

    def get_cielo_fee_for_amex
      if @subscription_payment
        tax_calc(cielo_installment_not_amex_tax)
      else
        self.payment.installments > 1 ? tax_calc_for_installment(cielo_installment_amex_tax) : tax_calc(cielo_installment_not_amex_tax)
      end
    end

    def get_cielo_fee_for_non_amex
      if @subscription_payment
        return tax_calc(cielo_tax)
      else
        current_tax = self.payment.gateway_data["card_brand"] == 'diners' ? installment_diners_tax : installment_not_diners_tax
        self.payment.installments > 1 ? tax_calc_for_installment(current_tax) : tax_calc(cielo_tax)
      end
    end

    def tax_calc acquirer_tax
      if @subscription_payment
        ((self.subscription.plan.amount * pagarme_tax) + cents_fee).round(2) + (self.subscription.plan.amount * acquirer_tax).round(2)
      else
        ((self.payment.value * pagarme_tax) + cents_fee).round(2) + (self.payment.value * acquirer_tax).round(2)
      end
    end

    def tax_calc_for_installment acquirer_tax
      (((self.payment.installment_value * self.payment.installments) * pagarme_tax) + cents_fee).round(2) + ((self.payment.installment_value * acquirer_tax).round(2) * self.payment.installments)
    end

    def cents_fee
      CatarsePagarme.configuration.credit_card_cents_fee.to_f
    end

    def pagarme_tax
      CatarsePagarme.configuration.pagarme_tax.to_f
    end

    def cielo_tax
      CatarsePagarme.configuration.cielo_tax.to_f
    end

    def stone_tax
      CatarsePagarme.configuration.stone_tax.to_f
    end

    def installment_diners_tax
      CatarsePagarme.configuration.cielo_installment_diners_tax.to_f
    end

    def installment_not_diners_tax
      CatarsePagarme.configuration.cielo_installment_not_diners_tax.to_f
    end

    def cielo_installment_amex_tax
      CatarsePagarme.configuration.cielo_installment_amex_tax.to_f
    end

    def cielo_installment_not_amex_tax
      CatarsePagarme.configuration.cielo_installment_not_amex_tax.to_f
    end

  end
end
