Template.userGuide.onCreated ->
  @selectedFeaturedTopic = new ReactiveVar 1
  @selectedSecondaryTopic = new ReactiveVar null

Template.userGuide.helpers
  activeFeatureMenu: (menuItem)->
    menuItem == Template.instance().selectedFeaturedTopic.get()

  activeFeatureContent: (contentItem)->
    contentItem == Template.instance().selectedFeaturedTopic.get()

  activeSecondaryMenu: (menuItem)->
    menuItem == Template.instance().selectedSecondaryTopic.get()

  activeSecondaryContent: (contentItem)->
    contentItem == Template.instance().selectedSecondaryTopic.get()

Template.userGuide.events
  'click .mode-selector.primary a': (event, instance) ->
    instance.selectedFeaturedTopic.set +$(event.currentTarget).data('topic')

  'click .mode-selector.secondary a': (event, instance) ->
    instance.selectedSecondaryTopic.set +$(event.currentTarget).data('topic')

  'click .show-more-info': (event) ->
    $(event.target).next().toggleClass('hidden').prev().remove()
