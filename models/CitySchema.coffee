'use strict'

citySchema = LocationSchema.extend
	name:
		type: String
		required: true
	code:
		type: String
		required: true
		index: true
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
