module CatarsePagarme
  class SubscriptionController < CatarsePagarme::ApplicationController
    MAX_SOFT_DESCRIPTOR_LENGTH = 13

    def create
      payment_method = params[:payment_method]
      plan = PagarMe::Plan.find_by_id(subscription.plan.gateway_id)

      info_hash = {
        postback_url: ipn_pagarme_index_url(
          host: CatarsePagarme.configuration.host,
          subdomain: CatarsePagarme.configuration.subdomain,
          protocol: CatarsePagarme.configuration.protocol
        ),
        :customer => {
          :email => subscription.user.email
        }
      }
      info_hash[:payment_method] = 'boleto' if payment_method == 'slip'
      info_hash[:card_hash] = params[:card_hash] if payment_method == 'credit_card'

      pagarme_subscription = PagarMe::Subscription.new(info_hash)

      pagarme_subscription.plan = plan

      pagarme_subscription.create

      subscription.update_attribute :state, pagarme_subscription.status
      subscription.update_attribute :gateway_data, pagarme_subscription.to_json

      response = { payment_status: pagarme_subscription.status }
      response[:boleto_url] = pagarme_subscription.current_transaction.boleto_url if payment_method == 'slip'
      render json: response
    rescue PagarMe::PagarMeError => e
      render json: { payment_status: 'failed', message: e.message }
    end

  end
end
