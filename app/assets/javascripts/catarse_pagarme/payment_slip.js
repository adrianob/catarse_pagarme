App.views.Pagarme.addChild('PaymentSlip', _.extend({
  el: '#payment_type_slip_section form',

  events: {
    'click input#build_boleto' : 'onBuildBoletoClick',
    'blur input' : 'checkInput'
  },

  activate: function(options){
    app.userDocumentView.undelegateEvents();
    app._userDocumentView = null;
    app.userDocumentView;
    this.$('#user_bank_account_attributes_owner_name').data('custom-validation', this.validateName);

    this.setupForm();
    this.message = this.$('.payment-error-message');
    this.$('#user_bank_account_attributes_name').brbanks();
  },

  onBuildBoletoClick: function(e){
    var that = this;

    if(!this.validate()){
      return false;
    }

    var parent = this.parent,
        post_url = '';

    e.preventDefault();
    $(e.currentTarget).hide();
    this.$('#payment-slip-instructions').slideUp('slow');
    that.parent.loader.show();

    if (typeof parent.contributionId !== 'undefined') {
      post_url = '/payment/pagarme/'+that.parent.contributionId+'/pay_slip.json';
    }
    else if (typeof parent.subscriptionId !== 'undefined') {
      post_url = '/payment/pagarme/'+that.parent.subscriptionId+'/pay_subscription.json?payment_method=slip&twitch_link='+$('#subscription_twitch_link').val();
    }

    $.post(post_url, null, 'json').success(function(response){
      parent.loader.hide();
      if(response.payment_status == 'failed'){
        that.message.find('.message-text').html(response.message);
        that.message.slideDown('slow');

        $(e.currentTarget).show();
      } else if(response.boleto_url) {
        var thank_you = $('#project_review').data('thank-you-path');

        if(thank_you){
          location.href = thank_you;
        } else {
          location.href = '/';
        }
      }
    });
  }

}, Skull.Form));
