module CatarsePagarme
  class PagarmeController < CatarsePagarme::ApplicationController

    def review
      contribution
      current_user.build_bank_account unless current_user.bank_account
    end

    def subscription_review
      subscription
      current_user.build_bank_account unless current_user.bank_account
      render :review
    end

  end
end
