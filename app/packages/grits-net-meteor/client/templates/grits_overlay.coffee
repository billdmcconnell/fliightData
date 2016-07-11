Template.gritsOverlay.onCreated ->
  @loaded = new ReactiveVar false

Template.gritsOverlay.onRendered ->
  instance = @
  @autorun ->
    if not Session.get('loading')
      setTimeout ( -> instance.loaded.set true ), 500

Template.gritsOverlay.helpers
  showCurtain: ->
    Session.get('loading')

  isLoaded: ->
    Template.instance().loaded.get()
