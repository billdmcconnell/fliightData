Template.helpLink.events
  'click .help-link': (event, instance) ->
    helpTemplate = $(event.currentTarget).data('template')
    Session.set 'helpTemplate', helpTemplate
    Session.set 'helpGuideState', true
    Session.set 'helpSubTopic', true
    $('.help--modal').modal 'show'
