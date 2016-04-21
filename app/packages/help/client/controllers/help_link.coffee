Template.helpLink.events
  'click .help-link': (event, instance) ->
    helpTemplate = $(event.currentTarget).data('template')
    Session.set 'helpTemplate', helpTemplate
    Session.set 'helpGuideState', true
    if instance.data.showTitle
      Session.set 'helpSubTopic', true
    else
      Session.set 'helpSubTopic', false
    $('.help--modal').modal 'show'
