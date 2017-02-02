_ignoreFields = []
_validFields = ['departure', 'effectiveDate', 'discontinuedDate']
_validOperators = ['$gte', '$gt', '$lte', '$lt', '$eq', '$ne', '$in', '$near', null]
_state = null # keeps track of the query string state
# local/private minimongo collection
_Collection = new (Mongo.Collection)(null)
# local/private Astronomy model for maintaining filter criteria
_Filter = Astro.Class(
  name: 'FilterCriteria'
  collection: _Collection
  transform: true
  fields: ['key', 'operator', 'value']
  validators: {
    key: [
        Validators.required(),
        Validators.string()
    ],
    operator: [
        Validators.required(),
        Validators.string(),
        Validators.choice(_validOperators)
    ],
    value: Validators.required()
  }
)

# GritsFilterCriteria, this object provides the interface for
# accessing the UI filter box. The setter methods may be called
# programmatically or the reactive var can be set by event handers
# within the UI.  The entire object maintains its own state.
#
# @note exports as a 'singleton'
class GritsFilterCriteria
  constructor: () ->
    self = this

    # reactive var used to update the UI when the query state has changed
    self.stateChanged = new ReactiveVar(null)

    # setup an instance variable that contains todays date.  This will be used
    # to set the initial Start and End dates to the Operating Date Range
    now = new Date()
    month = now.getMonth()
    date = now.getDate()
    year = now.getFullYear()
    self._today = new Date(year, month, date)
    # this._baseState keeps track of the initial plugin state after any init
    # methods have run
    self._baseState = {}

    # processing queue
    self._queue = null

    # reactive vars to track form binding
    #   departures
    self.departures = new ReactiveVar([])
    self.trackDepartures()

    #   operatingDateRangeStart
    self.operatingDateRangeStart = new ReactiveVar(null)
    self.trackOperatingDateRangeStart()
    #   operatingDateRangeEnd
    self.operatingDateRangeEnd = new ReactiveVar(null)
    self.trackOperatingDateRangeEnd()

    # airportCounts
    # during a simulation the airports are counted to update the heatmap
    self.airportCounts = {}

    # is the simulation running?
    self.isSimulatorRunning = new ReactiveVar(false)

    return
  # initialize the start date of the filter 'discontinuedDate'
  #
  # @return [String] dateString, formatted MM/DD/YY
  initStart: () ->
    self = this
    start = self._today
    self.createOrUpdate('discontinuedDate', {key: 'discontinuedDate', operator: '$gte', value: start})
    query = @getQueryObject()
    # update the state logic for the indicator
    _state = JSON.stringify(query)
    self._baseState = JSON.stringify(query)
    month = start.getMonth() + 1
    date = start.getDate()
    year = start.getFullYear()
    yearStr = year.toString().slice(2,4)
    self.operatingDateRangeStart.set(new Date(year, month, date))
    return "#{month}/#{date}/#{yearStr}"
  # initialize the end date through the 'effectiveDate' filter
  #
  # @return [String] dateString, formatted MM/DD/YY
  initEnd: () ->
    self = this
    end = moment(@_today).add(7, 'd').toDate()
    self.createOrUpdate('effectiveDate', {key: 'effectiveDate', operator: '$lte', value: end})
    # get the query object
    query = self.getQueryObject()
    # update the state logic for the indicator
    _state = JSON.stringify(query)
    self._baseState = JSON.stringify(query)
    month = end.getMonth() + 1
    date = end.getDate()
    year = end.getFullYear()
    yearStr = year.toString().slice(2,4)
    self.operatingDateRangeEnd.set(new Date(year, month, date))
    return "#{month}/#{date}/#{yearStr}"
  # Creates a new filter criteria and adds it to the collection or updates
  # the collection if it already exists
  #
  # @param [String] id, the name of the filter criteria
  # @return [Object] Astronomy model 'FilterCriteria'
  createOrUpdate: (id, fields) ->
    self = this
    if _.indexOf(_validFields, id) < 0
      throw new Error('Invalid filter: ' + id)
    obj = _Collection.findOne({_id: id})
    if obj
      obj.set(fields)
      if obj.validate() == false
        throw new Error(_.values(obj.getValidationErrors()))
      obj.save()
      return obj
    else
      _.extend(fields, {_id: id})
      obj = new _Filter(fields)
      if obj.validate() == false
        throw new Error(_.values(obj.getValidationErrors()))
      obj.save()
      return obj
  # removes a FilterCriteria from the collection
  #
  # @param [String] id, the name of the filter criteria
  # @optional [Function] cb, the callback method if removing async
  remove: (id, cb) ->
    self = this
    obj = _Collection.findOne({_id: id})
    if obj and cb
      obj.remove(cb)
      return
    if obj
      return obj.remove()
    else
      return 0
  # returns the query object used to filter the server-side collection
  #
  # @return [Object] query, a mongoDB query object
  getQueryObject: () ->
    self = this
    criteria = _Collection.find({})
    result = {}
    criteria.forEach((filter) ->
      value = {}
      k = filter.get('key')
      o = filter.get('operator')
      v = filter.get('value')
      if _.indexOf(['$eq'], o) >= 0
        value = v
      else
        value[o] = v
      result[k] = value
    )
    return result
  # compares the current state vs. the original/previous state
  compareStates: () ->
    self = this
    # postone execution to avoid 'flash' for the fast draw case.  this happens
    # when the user clicks a node or presses enter on the search and the
    # draw completes faster than the debounce timeout
    async.nextTick(() ->
      current = self.getCurrentState()
      if current != _state
        # do not notifiy on an empty query or the base state
        if current == "{}" || current == self._baseState
          self.stateChanged.set(false)

        else
          self.stateChanged.set(true)
          # disable [More...] button when filter has changed
          $('#loadMore').prop('disabled', true)
      else
        self.stateChanged.set(false)
    )
    return
  # gets the current state of the filter
  #
  # @return [String] the query object JSON.strigify
  getCurrentState: () ->
    self = this
    query = self.getQueryObject()
    return JSON.stringify(query)
  # get the original/previous state of the filter
  #
  # @return [String] the query object JSON.strigify
  getState: () ->
    _state
  # sets the original/previous state of the filter, this method will read the
  # current query object and store is as a JSON string
  setState: () ->
    self = this
    query = self.getQueryObject()
    _state = JSON.stringify(query)
    return
  # process the results of the meteor methods to get flights
  #
  # @param [Array] flights, an Array of flights to process
  process: (flights) ->
    self = this
    if self._queue != null
      self._queue.kill()
      async.nextTick(() ->
        self._queue = null
      )

    map = Template.gritsMap.getInstance()
    layerGroup = GritsLayerGroup.getCurrentLayerGroup()
    heatmapLayerGroup = Template.gritsMap.getInstance().getGritsLayerGroup(GritsConstants.HEATMAP_GROUP_LAYER_ID)

    count = Session.get(GritsConstants.SESSION_KEY_LOADED_RECORDS)

    throttleDraw = _.throttle(->
      layerGroup.draw()
      heatmapLayerGroup.draw()
    , 500)

    self._queue = async.queue(((flight, callback) ->
      # convert the flight into a node/path
      layerGroup.convertFlight(flight, 1, self.departures.get())
      # update the layer
      throttleDraw()
      # update the counter
      Session.set(GritsConstants.SESSION_KEY_LOADED_RECORDS , ++count)
      # done processing
      async.nextTick(-> callback())
    ), 4)

    # final method for when all items within the queue are processed
    self._queue.drain = ->
      layerGroup.finish()
      heatmapLayerGroup.finish()
      Session.set(GritsConstants.SESSION_KEY_LOADED_RECORDS, count)
      Session.set(GritsConstants.SESSION_KEY_IS_UPDATING, false)

    # add the flights to thet queue which will start processing
    self._queue.push(flights)
    return
  # applies the filter
  #
  # @param [Function] cb, the callback function
  more: (cb, limit=3000) ->
    # applying the filter is always EXPLORE mode
    Session.set(GritsConstants.SESSION_KEY_MODE, GritsConstants.MODE_EXPLORE)

    query = @getQueryObject()
    if _.isUndefined(query) or _.isEmpty(query)
      toastr.error(i18n.get('toastMessages.departureRequired'))
      Session.set(GritsConstants.SESSION_KEY_IS_UPDATING, false)
      return

    if Object.keys(query).every((k)-> !k.startsWith('departureAirport'))
      toastr.error(i18n.get('toastMessages.departureRequired'))
      Session.set(GritsConstants.SESSION_KEY_IS_UPDATING, false)
      return

    # set the state
    @setState()
    @compareStates()

    # remove the ignoreFields from the query
    _.each(_ignoreFields, (field) ->
      if query.hasOwnProperty(field)
        delete query[field]
    )

    # show the loading indicator and call the server-side method
    Session.set(GritsConstants.SESSION_KEY_IS_UPDATING, true)
    Meteor.call 'flightsByQuery', query, limit, (err, result) =>
      if err
        Meteor.gritsUtil.errorHandler(err)
        return
      {totalRecords, flights} = result

      if totalRecords > limit and limit != 0
        Session.set(GritsConstants.SESSION_KEY_IS_UPDATING, false)
        data =
          totalRecords: totalRecords
          flights: flights
          callback: cb
        Blaze.renderWithData Template.gritsConfirmModal, data, $('body')[0]
        return

      if Meteor.gritsUtil.debug
        console.log 'totalRecords: ', totalRecords

      Session.set(GritsConstants.SESSION_KEY_TOTAL_RECORDS, totalRecords)

      if totalRecords.length <= 0
        toastr.info(i18n.get('toastMessages.noResults'))
        Session.set(GritsConstants.SESSION_KEY_IS_UPDATING, false)
        return

      if _.isUndefined(flights) || flights.length <= 0
        toastr.info(i18n.get('toastMessages.noResults'))
        Session.set(GritsConstants.SESSION_KEY_IS_UPDATING, false)
        return
      # call the original callback function if its defined
      if cb && _.isFunction(cb)
        cb(null, flights)
      # process the flights
      @process(flights)

  # applies the filter; resets loadedRecords, and totalRecords
  #
  # @param [Function] cb, the callback function
  apply: (cb) ->
    self = this
    # allow the reactive var to be set before continue
    async.nextTick(() ->
      # reset the loadedRecords and totalRecords
      Session.set(GritsConstants.SESSION_KEY_LOADED_RECORDS, 0)
      Session.set(GritsConstants.SESSION_KEY_TOTAL_RECORDS, 0)
      # re-enable the loadMore button when a new filter is applied
      $('#loadMore').prop('disabled', false)
      # pass the callback function if its defined
      if cb && _.isFunction(cb)
        self.more(cb)
      else
        self.more()
    )
    return
  # sets the 'start' date from the filter and updates the filter criteria
  #
  # @param [Object] date, Date object or null to clear the criteria
  setOperatingDateRangeStart: (date) ->
    self = this

    # do not allow this to run prior to jQuery/DOM
    if _.isUndefined($) || _.isUndefined(Template.gritsSearch)
      return
    discontinuedDatePicker = Template.gritsSearch.getDiscontinuedDatePicker()
    if _.isNull(discontinuedDatePicker)
      return

    discontinuedDate = discontinuedDatePicker.data('DateTimePicker').date().toISOString()

    if _.isNull(date) || _.isNull(discontinuedDate)
      if _.isEqual(date, discontinuedDate)
        self.remove('discontinuedDate')
      else
        discontinuedDatePicker.data('DateTimePicker').date(null)
        self.operatingDateRangeStart.set(null)
      return

    if _.isEqual(date.toISOString(), discontinuedDate)
      # the reactive var is already set, change is from the UI
      self.createOrUpdate('discontinuedDate', {key: 'discontinuedDate', operator: '$gte', value: discontinuedDate})
    else
      discontinuedDatePicker.data('DateTimePicker').date(date)
      self.operatingDateRangeStart.set(date)
    return
  trackOperatingDateRangeStart: () ->
    self = this
    Meteor.autorun ->
      obj = self.operatingDateRangeStart.get()
      self.setOperatingDateRangeStart(obj)
      async.nextTick(() ->
        self.compareStates()
      )
    return
  # sets the 'end' date from the filter and updates the filter criteria
  #
  # @param [Object] date, Date object or null to clear the criteria
  setOperatingDateRangeEnd: (date) ->
    self = this

    # do not allow this to run prior to jQuery/DOM
    if _.isUndefined($) || _.isUndefined(Template.gritsSearch)
      return
    effectiveDatePicker = Template.gritsSearch.getEffectiveDatePicker()
    if _.isNull(effectiveDatePicker)
      return

    effectiveDate = effectiveDatePicker.data('DateTimePicker').date().toISOString()

    if _.isNull(date) || _.isNull(effectiveDate)
      if _.isEqual(date, effectiveDate)
        self.remove('effectiveDate')
      else
        effectiveDatePicker.data('DateTimePicker').date(null)
        self.operatingDateRangeEnd.set(null)
      return

    if _.isEqual(date.toISOString(), effectiveDate)
      # the reactive var is already set, change is from the UI
      self.createOrUpdate('effectiveDate', {
        key: 'effectiveDate'
        operator: '$lte'
        value: effectiveDate
      })
    else
      effectiveDatePicker.data('DateTimePicker').date(date)
      self.operatingDateRangeEnd.set(date)
    return
  trackOperatingDateRangeEnd: () ->
    self = this
    Meteor.autorun ->
      obj = self.operatingDateRangeEnd.get()
      self.setOperatingDateRangeEnd(obj)
      async.nextTick(() ->
        self.compareStates()
      )
    return
  # sets the departure input on the UI to the 'code'
  # specified, as well as, updating the underlying FilterCriteria.
  #
  # @param [String] code, an airport IATA code
  # @see http://www.iata.org/Pages/airports.aspx
  setDepartures: (code) ->
    # do not allow this to run prior to jQuery/DOM
    if _.isUndefined($)
      return
    if _.isUndefined(code)
      throw new Error('A code must be defined or null.')

    if _.isEqual(@departures.get(), code)
      # the call is from the UI
      if _.isNull(code)
        @remove('departure')
        return
      if _.isEmpty(code)
        @remove('departure')
        return
      if _.isArray(code)
        codes = code
      else
        codes = [code]
      departures = []

      # Clear all the property meta-nodes and recreate them.
      GritsMetaNode.resetPropertyNodes()
      allNodes = Template.gritsMap.getInstance()
        .getGritsLayerGroup(GritsConstants.ALL_NODES_GROUP_LAYER_ID)
        .getNodeLayer().getNodes()

      parsedCodes = _.chain(codes)
        .map (_id)->
          if _.contains(_id, ":")
            [field, value] = _id.split(":")
            airportIds = _.chain(Meteor.gritsUtil.airports)
              .map((airport)->
                if airport[field] == value
                  [airport._id, true]
                else
                  null
              )
              .compact()
              .object()
              .value()
            filteredNodes = allNodes.filter (x)->airportIds[x._id]
            metaNode = GritsMetaNode.create(filteredNodes, _id)
            return Object.keys(airportIds)
          else if _id.indexOf(GritsMetaNode.PREFIX) >= 0
            node = GritsMetaNode.find(_id)
            return _.pluck(node?._children or [], '_id')
          else
            return [_id.toUpperCase()]
        .flatten()
        .value()
      @createOrUpdate('departure', {
        key: 'departureAirport._id'
        operator: '$in'
        value: parsedCodes
      })
    else
      if _.isNull(code)
        Template.gritsSearch.getDepartureSearchMain().tokenfield('setTokens', [])
        @departures.set([])
      else if _.isEmpty(code)
        Template.gritsSearch.getDepartureSearchMain().tokenfield('setTokens', [])
        @departures.set([])
      else if _.isArray(code)
        Template.gritsSearch.getDepartureSearchMain().tokenfield('setTokens', code)
        @departures.set(code)
      else
        Template.gritsSearch.getDepartureSearchMain().tokenfield('setTokens', [code])
        @departures.set([code])
  trackDepartures: () ->
    self = this
    Meteor.autorun ->
      obj = self.departures.get()
      if _.isEmpty(obj)
        # checks are necessary as Tracker autorun will fire before the DOM
        # is ready and the Template.gritsMap.onRenered is called
        if !(_.isUndefined(Template.gritsMap) || _.isUndefined(Template.gritsMap.getInstance))
          map = Template.gritsMap.getInstance()
          if !_.isNull(map)
            layerGroup = GritsLayerGroup.getCurrentLayerGroup()
            # clears the sub-layers and resets the layer group
            if layerGroup != null
              layerGroup.reset()
      self.setDepartures(obj)
      async.nextTick(() ->
        self.compareStates()
      )

  # returns a unique list of tokens from the search bar
  getOriginIds: () ->
    query = @getQueryObject()
    query['departureAirport._id']['$in']

  # handle setup of subscription to SimulatedIteneraries and process the results
  processSimulation: (simPas, simId) ->
    # get the heatmapLayerGroup
    heatmapLayerGroup = Template.gritsMap.getInstance().getGritsLayerGroup(GritsConstants.HEATMAP_GROUP_LAYER_ID)
    # get the current mode groupLayer
    layerGroup = GritsLayerGroup.getCurrentLayerGroup()
    if layerGroup == null
      return

    # reset the layers/counters
    layerGroup.reset()
    heatmapLayerGroup.reset()
    loaded = 0
    # initialize the status-bar counter
    Session.set(GritsConstants.SESSION_KEY_LOADED_RECORDS, loaded)
    # reset the airportCounts
    @airportCounts = {}
    originIds = @getOriginIds()
    _updateHeatmap = _.throttle(=>
      Heatmaps.remove({})
      # map the airportCounts object to one with percentage values
      airportPercentages = _.object([key, val / loaded] for key, val of @airportCounts)
      # key the heatmap to the departure airports so it can be filtered
      # out if the query changes.
      airportPercentages._id = originIds.sort().join("")
      Heatmap.createFromDoc(airportPercentages, Meteor.gritsUtil.airportsToLocations)
    , 500)

    _throttledDraw = _.throttle(->
      layerGroup.draw()
      heatmapLayerGroup.draw()
    , 500)

    @simulationItineraries = Meteor.subscribe('SimulationItineraries', simId)
    options =
      transform: null

    _doWork = (id, fields) =>
      if @airportCounts[fields.destination]
        @airportCounts[fields.destination]++
      else
        @airportCounts[fields.destination] = 1
      loaded += 1
      layerGroup.convertItineraries(fields, fields.origin)
      # update the simulatorProgress bar
      if simPas > 0
        progress = Math.ceil((loaded / simPas) * 100)
        Template.gritsSearch.simulationProgress.set(progress)
        Session.set(GritsConstants.SESSION_KEY_LOADED_RECORDS, loaded)
      if loaded == simPas
        #finaldraw
        Template.gritsSearch.simulationProgress.set(100)
        Session.set(GritsConstants.SESSION_KEY_LOADED_RECORDS, loaded)
        _updateHeatmap()
        layerGroup.finish()
        heatmapLayerGroup.finish()
        @isSimulatorRunning.set(false)
      else
        _updateHeatmap()
        _throttledDraw()

    itineraryQuery = Itineraries.find({'simulationId': simId}, options)
    numItineraries = itineraryQuery.count()

    if numItineraries == simPas
      itineraryQuery.forEach Meteor.gritsUtil.smoothRate (itinerary) ->
          _doWork(itinerary._id, itinerary)
    else
      itineraryQuery.observeChanges({
        added: Meteor.gritsUtil.smoothRate (id, fields) ->
          _doWork(id, fields)
      })
    return

  # starting a simulation
  startSimulation: (simPas, startDate, endDate) ->
    departures = @departures.get()
    if departures.length == 0
      toastr.error(i18n.get('toastMessages.departureRequired'))
      return

    if @isSimulatorRunning.get()
      return

    # switch mode
    Session.set(GritsConstants.SESSION_KEY_MODE, GritsConstants.MODE_ANALYZE)

    # let the user know the simulation started
    Template.gritsSearch.simulationProgress.set(1)

    # set the simulation as running
    @isSimulatorRunning.set(true)

    Meteor.call('startSimulation', simPas, startDate, endDate, @getOriginIds(), (err, res) =>
      # handle any errors
      if err
        Meteor.gritsUtil.errorHandler(err)
        console.error(err)
        return
      if res.hasOwnProperty('error')
        Meteor.gritsUtil.errorHandler(res)
        console.error(res)
        return

      # set the reactive var on the template
      Template.gritsDataTable.simId.set(res.simId)

      # update the url
      FlowRouter.go('/simulation/'+res.simId)

      # set the status-bar total counter
      Session.set(GritsConstants.SESSION_KEY_TOTAL_RECORDS, simPas)

      # setup parameters for the subscription to SimulationItineraries
      @processSimulation(simPas, res.simId)
    )

  # reset the start date of the filter
  resetStart: () ->
    self = this
    start = self._today
    month = start.getMonth()
    date = start.getDate()
    year = start.getFullYear()
    self.operatingDateRangeStart.set(new Date(year, month, date))
    return
  # reset the end date of the filter
  resetEnd: () ->
    self = this
    end = moment(self._today).add(7, 'd').toDate()
    month = end.getMonth()
    date = end.getDate()
    year = end.getFullYear()
    self.operatingDateRangeEnd.set(new Date(year, month, date))
    return
  # resets the filter
  reset: () ->
    self = this
    # reset the departures
    self.setDepartures null

    # reset the start and end dates
    self.resetStart()
    self.resetEnd()

    # reset counters
    Session.set GritsConstants.SESSION_KEY_LOADED_RECORDS, 0
    Session.set GritsConstants.SESSION_KEY_TOTAL_RECORDS, 0

    # reset includeNearby
    $('#includeNearbyAirports').prop 'checked', false
    $("#includeNearbyAirportsRadius").val 50

    # determine the current mode
    mode = Session.get GritsConstants.SESSION_KEY_MODE
    if mode == GritsConstants.MODE_ANALYZE
      # set isSimulatorRunning to false
      self.isSimulatorRunning.set(false)
      # stop any existing subscription
      if self.simulationItineraries != null
        self.simulationItineraries.stop()
        self.simulationItineraries = null;

      # remove disabled class
      $('#startSimulation').removeClass('disabled')
      # reset number of passengers
      $('#simulatedPassengersInputSlider').slider('setValue', 1000)
      $('#simulatedPassengersInputSliderValIndicator').html(1000)
      FlowRouter.route('/')
      return

GritsFilterCriteria = new GritsFilterCriteria() # exports as a singleton
