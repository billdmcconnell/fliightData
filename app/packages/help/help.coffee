if Meteor.isClient

  Meteor.startup ->
    visited = localStorage?.getItem 'lastVisit'
    unless visited
      Session.set 'visited', false
    # localStorage?.setItem 'lastVisit', Date.now()

  Template.help.onRendered ->
    console.log Session.get 'visited'
    if Session.get('visited')?
      @$('#help-modal').modal('show')
