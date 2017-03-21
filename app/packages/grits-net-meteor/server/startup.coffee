fs = Npm.require('fs');

_warmupMongoFlights = (done) ->
  query = {"departureAirport._id":{"$in":["BOS"]}}
  console.log('warmup flights')
  async.eachSeries([0..9],
    (x, callback) ->
      Meteor.call('flightsByQuery', query, 100, x*100, (err, res) ->
        callback()
      )
    (err) ->
      done()
  )
  return
_warmupMongoAirports = (done) ->
  letters = ['b','o','s','t','o','n']
  console.log('warmup airports')
  async.eachSeries([0..9],
    (x, callback) ->
      if x < 5
        search = letters.slice().splice(0,x).join('')
      else
        search = letters.join('')
      Meteor.call('typeaheadAirport', search, x*10, (err, res) ->
        callback()
      )
    (err) ->
      done()
  )
  return
_warmupMongoItineraries = (done) ->
  query = {"origin":{"$in":["BNA"]}}
  console.log('warmup itineraries')
  async.eachSeries([0..9],
    (x, callback) ->
      Meteor.call('itinerariesByQuery', query, 100, x*100, (err, res) ->
        callback()
      )
    (err) ->
      done()
  )
  return
_cacheActiveAirports = (done) ->
  console.log('cache active airports')
  Meteor.call('findActiveAirports', done)
  return

_ensureIndexes = (done) ->
  console.log('ensure indexes')
  # Ensure geo index on airport location
  Airports._ensureIndex
    loc: '2dsphere'
  done()

fixAirportLocations = () ->
  syncReadFile = Meteor.wrapAsync(fs.readFile)
  syncReadFile process.env.PWD + '/data/errorports.csv', 'utf8', (err, data) ->
    if err
      console.log "Error reading csv", err
      return
    rows = data.split('\n')
    for row in rows
      columns = row.split(',')
      airportCode = columns[0]
      airport = Airports.findOne({_id: airportCode})
      api_key = '84d572528e84d94f59e429867dbd1bed'
      url =  "https://api.opencagedata.com/geocode/v1/json?q=#{airport.loc.coordinates[1]}%2C#{airport.loc.coordinates[0]}&pretty=1&key=" + api_key;
      response = Meteor.http.call("GET", url)
      responseObject = JSON.parse(response.content)
      locationData = JSON.parse(response.content).results[0].components
      Airports.update airportCode, {
        $set: {
          city: locationData.local_administrative_area || locationData.town || locationData.village || locationData.suburb,
          country: locationData.country_code,
          countryName: locationData.country,
          stateName: locationData.state,
          globalRegion: null
        }
      }

warmupMongo = () ->
  start = new Date()
  console.log('starting warmup')
  async.auto({
    'ensureIndexes': (callback,  result) ->
      _ensureIndexes(callback)
    'warmupMongoFlights': (callback, result) ->
      _warmupMongoFlights(callback)
    'warmupMongoAirports': (callback, result) ->
      _warmupMongoAirports(callback)
    'warmupMongoItineraries': (callback, result) ->
      _warmupMongoItineraries(callback)
    'cacheActiveAirports': (callback, result) ->
      _cacheActiveAirports(callback)
  }, (err, result) ->
    console.log('warmup done(ms): ', new Date() - start)
  )

Meteor.startup ->
  # if we're not in a test environment, warmup mongodb
  Meteor.call('isTestEnvironment', (err, res) ->
    if res == false
      warmupMongo()
  )
  fixAirportLocations()
  # setup i18n
  i18n.addLanguage('en', 'English')
