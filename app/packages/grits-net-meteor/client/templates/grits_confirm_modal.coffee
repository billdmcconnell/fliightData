Template.gritsConfirmModal.onRendered ->
  Meteor.defer =>
    $modal = @$('.confirm--modal')
    $modal.modal('show')
    $modal.on 'hide.bs.modal', (event) ->
      $modal.remove()

Template.gritsConfirmModal.events
  'click .cancel': (event, instance) ->
    GritsFilterCriteria.process(instance.data.flights)
    instance.$('.confirm--modal').modal('hide')

  'click .load-all': (event, instance) ->
    GritsFilterCriteria.more(instance.data.callback, 0)
    instance.$('.confirm--modal').modal('hide')
