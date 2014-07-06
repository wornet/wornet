'use strict'

module.exports = new Schema
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
		validate: [regex('simple-text'), 'invalid title']
		trim: true
	content:
		type: String
		trim: true
	allDay:
		type: Boolean
		default: false
	url: String