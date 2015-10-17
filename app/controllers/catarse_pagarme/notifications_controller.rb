module CatarsePagarme
  class NotificationsController < CatarsePagarme::ApplicationController
    skip_before_filter :authenticate_user!

    def create
      if (params['object'] == 'transaction') && payment
        payment.payment_notifications.create(contribution: payment.contribution, extra_data: params.to_json)

        if PagarMe::validate_fingerprint(payment.try(:gateway_id), params[:fingerprint])
          delegator.change_status_by_transaction(params[:current_status])
          delegator.update_transaction

          return render nothing: true, status: 200
        end
      elsif (params['object'] == 'subscription') && subscription
        subscription.subscription_notifications.create(extra_data: params.to_json)

        if PagarMe::validate_fingerprint(subscription.try(:gateway_id), params[:fingerprint])
          subscription.pagarme_subscription_delegator.change_status_by_transaction(params[:current_status])

          return render nothing: true, status: 200
        end
      end

      render nothing: true, status: 404
    end

    protected

    def payment
      @payment ||=  PaymentEngines.find_payment({ gateway_id: params[:id] })
    end

    def subscription
      @subscription ||= Subscription.find_by_gateway_id params[:id]
    end
  end
end
