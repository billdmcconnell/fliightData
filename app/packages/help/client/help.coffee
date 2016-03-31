Meteor.startup ->
  visited = localStorage?.getItem 'lastVisit'
  unless visited
    Session.set 'visited', false
  localStorage?.setItem 'lastVisit', Date.now()

Template.help.onRendered ->
  sideBarWidth = $('#sidebar').width()
  mapViewWidth = sideBarWidth + $('#tableSidebar').width()
  mapViewCenter = @$('#help-modal').width() / mapViewWidth
  modalLeftPosition = mapViewCenter + sideBarWidth
  @$('#help-modal').css 'left', modalLeftPosition
  if Session.get('visited')?
    @$('#help-modal').modal 'show'
