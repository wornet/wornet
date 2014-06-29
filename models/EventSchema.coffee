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
		required: true
		validate: [regex('simple-text'), 'invalid title']
		trim: true
	content:
		type: String
		required: true
		trim: true
	allDay:
		type: Boolean
		default: false
	url: String
