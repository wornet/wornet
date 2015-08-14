'use strict'

module.exports = (router) ->

	router.get '/loaded', (req, res) ->

		res.publicJson loaded: GeoPackage.loaded()

	router.get '/country/name/:code', (req, res) ->

		res.publicJson name: GeoPackage.countryName req.params.code

	router.get '/country/code/:name', (req, res) ->

		res.publicJson code: GeoPackage.countryCode req.params.name

	router.get '/city/name/contains/:query', (req, res) ->

		City.contains req.params.query, (err, cities) ->

			if err
				res.serverError err
			else
				res.publicJson
					query: req.params.query
					cities: cities

	router.get '/city/name/contains/:country/:query', (req, res) ->

		City.contains req.params.country, req.params.query, (err, cities) ->

			if err
				res.serverError err
			else
				res.publicJson
					query: req.params.query
					cities: cities

	router.get '/city/name/start-with/:query', (req, res) ->

		City.startWith req.params.query, (err, cities) ->

			if err
				res.serverError err
			else
				res.publicJson
					time: time()
					query: req.params.query
					cities: cities


	router.get '/city/name/start-with/:country/:query', (req, res) ->

		City.startWith req.params.country, req.params.query, (err, cities) ->

			if err
				res.serverError err
			else
				res.publicJson
					query: req.params.query
					cities: cities

	router.get '/city/name/:query', (req, res) ->

		City.find code: req.params.query.accents(), (err, cities) ->

			if err
				res.serverError err
			else
				res.publicJson
					query: req.params.query
					cities: cities

	router.get '/city/name/:country/:query', (req, res) ->

		where =
			code: req.params.query.accents()
			country: req.params.country.accents()
		City.find where, (err, cities) ->

			if err
				res.serverError err
			else
				res.publicJson
					query: req.params.query
					cities: cities

	router.get '/city/distance/:country1/:city1/:country2/:city2', (req, res) ->

		parallel
			city1: City.findOne.bind City,
				code: req.params.city1.accents()
				country: req.params.country1.accents()
			city2: City.findOne.bind City,
				code: req.params.city2.accents()
				country: req.params.country2.accents()
		, (results) ->
			res.publicJson distance: GeoPackage.distance results.city1, results.city2
		, (err) ->
			res.serverError err

	router.get '/distance/:lat1/:long1/:lat2/:long2', (req, res) ->

		res.publicJson distance: GeoPackage.distance req.params.lat1, req.params.long1, req.params.lat2, req.params.long2

	router.get '/sector/:lat/:long', (req, res) ->

		res.publicJson
			coordsUnit: GeoPackage.coordsUnit req.params.lat, req.params.long
			sector: GeoPackage.sector req.params.lat, req.params.long

	router.get '/sectors/closest/:distance/:lat/:long', (req, res) ->

		distance = req.params.distance * 1
		if distance > 150000
			res.serverError new PublicError s("150 km maximum")
		else
			res.publicJson
				sectors: GeoPackage.closestSectors req.params.lat, req.params.long, distance

	router.get '/cities/closest/:distance/:lat/:long', (req, res) ->

		distance = req.params.distance * 1
		if distance > 150000
			res.serverError new PublicError s("150 km maximum")
		else
			next = (lat, long) ->
				GeoPackage.closestCities lat, long, distance, (err, cities) ->
					if err
						res.serverError err
					else
						res.publicJson
							cities: cities
			if /^[a-z]+$/i.test req.params.lat
				where =
					code: req.params.long.accents()
					country: req.params.lat.accents()
				City.findOne where, (err, city) ->
					if err
						res.serverError err
					else if city
						next city.latitude, city.longitude
					else
						res.serverError new PublicError s("Ville introuvable")
			else
				next req.params.lat, req.params.long
