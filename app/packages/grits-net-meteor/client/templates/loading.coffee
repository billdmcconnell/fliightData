centerLoadingSpinner = ->
  windowWidth = $(window).width()
  loadingContainerWidth = $('#filterLoading .spinner').width()
  $sidebar = $('#sidebar')
  sidebarWidth = $sidebar.width()
  $sidebarTabular = $('#tableSidebar')
  sidebarMenuWidth = $('.sidebar--tab-container').width()
  rightSideBarWidth = 3
  leftSideBarWidth =
    if $sidebar.offset().left < 0 then sidebarMenuWidth else sidebarWidth
  unless $sidebarTabular.offset().left > windowWidth - 10
    rightSideBarWidth = $sidebarTabular.width()

  mapViewWidth = windowWidth - leftSideBarWidth - rightSideBarWidth
  loadingSpinnerPosition = (mapViewWidth / 2) + leftSideBarWidth
  $('#filterLoading .spinner').css 'left', "#{loadingSpinnerPosition}px"

Template.loading.onRendered ->
  @autorun ->
    if Session.get('filtering')
      window.addEventListener 'resize', centerLoadingSpinner
      Meteor.defer ->
        centerLoadingSpinner()
    else
      window.removeEventListener 'resize', ->

Template.loading.helpers
  isFiltering: ->
    Session.get 'filtering'
