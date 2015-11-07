module CatarsePagarme
  class NotificationsController < CatarsePagarme::ApplicationController
    include FeeCalculatorConcern
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

        if PagarMe::validate_fingerprint(subscription.try(:gateway_id), params[:fingerprint])
          pagarme_subscription = PagarMe::Subscription.find_by_id(subscription.gateway_id)
          subscription.update_attribute :gateway_data, pagarme_subscription.to_json if pagarme_subscription
          notification = subscription.subscription_notifications.create(extra_data: params.to_json)
          notification.update_attribute :gateway_fee, get_fee('subscription')
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
