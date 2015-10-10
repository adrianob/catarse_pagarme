CatarsePagarme::Engine.routes.draw do
  resources :pagarme, only: [], path: "payment/pagarme" do

    member do
      get  :review
      get  :subscription_review
      get  :second_slip, to: 'slip#update'
      post :pay_credit_card, to: 'credit_cards#create'
      post :pay_slip, to: 'slip#create'
      post :pay_subscription, to: 'subscription#create'
    end

    collection do
      post :ipn, to: 'notifications#create'
    end

  end
end
