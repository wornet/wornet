'use strict'

loadedAtInit = 0

loadCounter = 0

latitudeUnit = 0

sectoreLatitudeMax = 0

GeoPackage =

	latitudeMin: -90 # degrees

	latitudeMax: 90 # degrees

	longitudeMin: -180 # degrees

	longitudeMax: 180 # degrees

	unit: 5000 # meters

	radiusOfTheEarth: 6371000 # meters

	citiesCount: 3170253

	countries: require __dirname + '/../system/countries'

	latitudeUnit: (lat) ->
		@boundaryLatitude lat // latitudeUnit * latitudeUnit

	longitudeUnit: (lat, long) ->
		@sector(lat, long).longitude

	boundaryLatitude: (lat) ->
		while lat > @latitudeMax
			lat += @latitudeMin - @latitudeMax
		while lat < @latitudeMin
			lat += @latitudeMax - @latitudeMin
		lat

	boundaryLongitude: (long) ->
		while long > @longitudeMax
			long -= @longitudeMax - @longitudeMin
		while long < @longitudeMin
			long += @longitudeMax - @longitudeMin
		long

	coordsUnit: (lat, long) ->
		lat = @latitudeUnit lat
		if lat < 0
			lat += latitudeUnit
		circle = 2 * @distance lat, 0, lat, @longitudeMax
		sectors = circle // @unit
		degrees = @longitudeMax - @longitudeMin
		unit = degrees / sectors
		long = @boundaryLongitude long // unit * unit
		latitude: lat
		longitude: long
		latitudeUnit: latitudeUnit
		longitudeUnit: unit

	approximateCoordinates: (lat, long) ->
		@coordsUnit(lat, long).columns ['latitude', 'longitude']

	sector: (lat, long) ->
		@coordsToSector @coordsUnit lat, long

	sectorToIdentifier: (sector) ->
		base = 2 * sectoreLatitudeMax + 1
		lat = sectoreLatitudeMax + sector.latitude
		long = base + sector.longitude
		long * base + lat

	sectorIdentifier: (lat, long) ->
		@sectorToIdentifier @sector lat, long

	coordsToSector: (coords) ->
		latitude: coords.latitude // coords.latitudeUnit
		longitude: coords.longitude // coords.longitudeUnit

	coordsInDistance: (coords, lat, long, distance = @unit) ->
		_lat = coords.latitude
		_long = coords.longitude
		if _lat < lat
			_lat += coords.latitudeUnit
		if _long < long
			_long += coords.longitudeUnit
		_lat = @boundaryLatitude _lat
		_long = @boundaryLongitude _long
		distance >= @distance lat, long, _lat, _long

	closestEWSectors: (sectors, lat, long, coords, distance = @unit) ->
		if @coordsInDistance coords, lat, long, distance
			sector = @coordsToSector coords
			sectors.push sector
			_coords = coords.copy()
			_sector = sector.copy()
			do dec = =>
				_sector.latitude--
				_coords.latitude = @boundaryLatitude _sector.latitude * _coords.latitudeUnit
				return
			while @coordsInDistance _coords, lat, long, distance
				sectors.push @coordsToSector _coords
				do dec
			_sector = sector.copy()
			do inc = =>
				_sector.latitude++
				_coords.latitude = @boundaryLatitude _sector.latitude * _coords.latitudeUnit
				return
			while distance > @distance lat, long, _coords.latitude, long
				sectors.push @coordsToSector _coords
				do inc
		return

	closestSectors: (lat, long, distance = @unit) ->
		coords = @coordsUnit lat, long
		sectors = []
		@closestEWSectors sectors, lat, long, coords, distance
		length = 0
		_coords = coords.copy()
		do dec = =>
			longitude = _coords.longitude // _coords.longitudeUnit
			while longitude is _coords.longitude // _coords.longitudeUnit
				_coords.longitude = @boundaryLongitude _coords.longitude - _coords.longitudeUnit / 2
			return
		until sectors.length is length
			length = sectors.length
			@closestEWSectors sectors, lat, long, _coords, distance
			do dec
		length = 0
		_coords = coords.copy()
		do inc = =>
			longitude = _coords.longitude // _coords.longitudeUnit
			while longitude is _coords.longitude // _coords.longitudeUnit
				_coords.longitude = @boundaryLongitude _coords.longitude + _coords.longitudeUnit / 2
			return
		until sectors.length is length
			length = sectors.length
			@closestEWSectors sectors, lat, long, _coords, distance
			do inc
		sectors

	closestCities: (lat, long, distance, done) ->
		if 'function' is typeof distance
			done = distance
			distance = @unit
		sectors = for sector in @closestSectors lat, long, distance
			@sectorToIdentifier sector
		City.find sector: $in: sectors, (err, cities) ->
			if err
				done err
			else
				done(null, cities
					.map (city) ->
						city.toCloseCity lat, long
					.filter (city) ->
						city.distance <= distance
					.sort (city1, city2) ->
						if city1.distance > city2.distance
							1
						else if city1.distance is city2.distance
							0
						else
							-1
				)

	countryCode: (name) ->
		name = name.accents()
		code = null
		length = 9999
		for _code, country of @countries
			country = country.accents()
			if country is name
				return _code.toLowerCase()
			if country.length < length and country.contains name
				length = country.length
				code = _code
		code.toLowerCase()

	countryName: (code) ->
		code = code.toUpperCase()
		name = @countries[code] || null
		if name
			name = name.capitalize()
		name

	distance: (lat1, lon1, lat2, lon2) ->
		if arguments.length is 2
			lon2 = lon1.longitude
			lat2 = lon1.latitude
			lon1 = lat1.longitude
			lat1 = lat1.latitude
		lat1 = floatval lat1
		lon1 = floatval lon1
		lat2 = floatval lat2
		lon2 = floatval lon2
		R = @radiusOfTheEarth
		φ1 = lat1.toRadians()
		φ2 = lat2.toRadians()
		Δφ = (lat2-lat1).toRadians()
		Δλ = (lon2-lon1).toRadians()

		a = Math.sin(Δφ / 2) * Math.sin(Δφ / 2) +
			Math.cos(φ1) * Math.cos(φ2) *
			Math.sin(Δλ / 2) * Math.sin(Δλ / 2)
		c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a))

		R * c

	loaded: ->
		(loadedAtInit + loadCounter) / @citiesCount

	init: ->
		arc = @distance @latitudeMin, 0, @latitudeMax, 0
		sectors = arc // @unit
		degrees = @latitudeMax - @latitudeMin
		latitudeUnit = degrees / sectors
		sectoreLatitudeMax = @sector(@latitudeMax, 0).latitude
		City.count (err, count) =>
			loadedAtInit = count
			if err or count < @citiesCount
				@seed count

	seed: (offset) ->
		Reader = require 'line-by-line'
		lines = new Reader __dirname + '/../system/cities.csv',
			encoding: 'utf-8'
			skipEmptyLines: true
		header = true
		columns = ['country', 'code', 'name', 'region', 'population', 'latitude', 'longitude']

		lines.on 'error', (err) ->
			warn err

		offset = 0
		country = null
		lines.on 'line', (line) =>
			unless header
				unless offset
					data = line.split /,/g
					city = {}
					for column, i in columns
						city[column] = data[i]
					if city.population
						city.population *= 1
					else
						delete city.population
					unless city.region
						delete city.region
					city.latitude *= 1
					city.longitude *= 1
					sector = @sector city.latitude, city.longitude
					city.latitudeSector = sector.latitude
					city.longitudeSector = sector.longitude
					city.sector = @sectorToIdentifier sector
					if city.country isnt country
						country = city.country
						console['log'] 'Load cities from country ' + @countryName country
					City.create city, (err) ->
						unless err
							loadCounter++
				else
					offset--
			else
				header = false

		lines.on 'end', ->
			console['log'] '\n\n\n===================================='
			console['log'] 'All cities loaded'
			console['log'] '====================================\n\n\n'
			City.count (err, count) =>
				loadedAtInit = count

module.exports = GeoPackage
