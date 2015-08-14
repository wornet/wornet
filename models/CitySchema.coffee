'use strict'

citySchema = new Schema
	name:
		type: String
		required: true
	code:
		type: String
		required: true
		index: true
	latitude:
		type: Number
		required: true
	longitude:
		type: Number
		required: true
	latitudeSector:
		type: Number
		required: true
	longitudeSector:
		type: Number
		required: true
	sector:
		type: Number
		required: true
	country:
		type: String
		required: true
		index: true
	region:
		type: String
	population:
		type: Number

citySchema.statics.contains = (country, query, done) ->
	if 'function' is typeof query
		done = query
		query = country
		country = null
	where = code: query.toSearchRegExp()
	if country
		where.country = country
	@find where, done

citySchema.statics.startWith = (country, query, done) ->
	if 'function' is typeof query
		done = query
		query = country
		country = null
	where = code: ('^' + query).toSearchRegExp()
	if country
		where.country = country
	@find where, done

citySchema.methods.closest = (distance, done) ->
	GeoPackage.closestCities @latitude, @longitude, distance, done

citySchema.methods.toCloseCity = (lat, long) ->
	city = @toObject()
	delete city._id
	delete city.__v
	city.distance = GeoPackage.distance @latitude, @longitude, lat, long
	city

citySchema.index
		code: 1
		country: 1
		region: 1
	,
		unique: true

citySchema.index
	latitudeSector: 1
	longitudeSector: 1

citySchema.index sector: 1

module.exports = citySchema
