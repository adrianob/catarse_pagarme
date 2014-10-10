App.addChild('PagarmeForm', {
  el: 'form.pagarme',

  activate: function() {
    this.message = this.$('.next_step_after_valid_document .alert-danger');
    this.loader = this.$('.loader img');

    this.contributionId = $('input#contribution_id').val();
    this.projectId = $('input#project_id').val();
  }
});

