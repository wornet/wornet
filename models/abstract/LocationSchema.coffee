'use strict'

###
@abstract
@class
###

LocationSchema = ->
	throw new Error "LocationSchema is an abstract class and cannot be instancied"

###
@abstract
@class
###

LocationSchema.extend = (columns, options) ->
	extend columns,
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

	schema = new Schema columns, options

	schema.methods.closest = (distance, done) ->
		GeoPackage.closestCities @latitude, @longitude, distance, done

	schema.methods.toCloseCity = (lat, long) ->
		city = @toObject()
		delete city._id
		delete city.__v
		city.distance = GeoPackage.distance @latitude, @longitude, lat, long
		city

	schema

module.exports = LocationSchema
