'use strict'

module.exports = new Schema
	user:
		type: ObjectId
		ref: 'UserSchema'
	registerDate: Date
	start:
		type: Date
		required: true
	end: Date
	title:
		type: String
		validate: [regex('simple-text'), 'invalid title']
		trim: true
	content:
		type: String
		trim: true
	allDay:
		type: Boolean
		default: false
	url: String

.pre 'save', (next) ->
	unless @registerDate
		@registerDate = new Date
	next()