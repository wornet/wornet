'use strict'

eventSchema = LocationSchema.extend
	user:
		type: ObjectId
		ref: 'UserSchema'
	registerDate:
		type: Date
		default: Date.now
	start:
		type: Date
		required: true
	end: Date
	title:
		type: String
		validate: [
			regex('simple-text')
			'invalid title'
		]
		trim: true
	content:
		type: String
		trim: true
	allDay:
		type: Boolean
		default: false
	participantsLimit:
		type: Number
	author:
		name:
			type: String
		type:
			type: String
			enum: [
				null
				""
				"startup"
				"person"
				"association"
				"business"
			]
	acceptMode:
		type: String
		enum: [
			null,
			"auto"
			"manual"
		]
	country:
		type: String
	city:
		type: ObjectId
		ref: 'CitySchema'
	address:
		type: String
	url: String
,
	toObject:
		virtuals: true
	toJSON:
		virtuals: true

module.exports = eventSchema
