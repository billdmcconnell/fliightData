Meteor.startup ->
  Session.set 'helpTemplate', 'userGuide'
  visited = localStorage?.getItem 'lastVisit'
  unless visited
    Session.set 'helpGuideState', false
  localStorage?.setItem 'lastVisit', Date.now()

Template.help.onRendered ->
  sideBarWidth = $('#sidebar').width()
  mapViewWidth = sideBarWidth + $('#tableSidebar').width()
  mapViewCenter = @$('#help-modal').width() / mapViewWidth
  modalLeftPosition = mapViewCenter + sideBarWidth
  @$('.help--modal').css 'left', modalLeftPosition
  if Session.get('helpGuideState')?
    @$('.help--modal').modal 'show'

Template.help.helpers
  helpTemplate: ->
    Session.get 'helpTemplate'
  data: ->
    showTitle: Session.get 'helpSubTopic'
