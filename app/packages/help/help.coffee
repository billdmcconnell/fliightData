Meteor.startup ->
  visited = localStorage?.getItem 'lastVisit'
  unless visited
    Session.set 'visited', false
  localStorage?.setItem 'lastVisit', Date.now()

if Meteor.isClient
  Template.help.onRendered ->
    console.log Session.get 'visited'
    if Session.get('visited')?
      @$('#help-modal').modal('show')
