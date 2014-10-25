'use strict'

statusSchema = BaseSchema.extend
	date:
		type: Date
		default: Date.now
		required: true
	author:
		type: ObjectId
		ref: 'UserSchema'
		required: true
	at:
		type: ObjectId
		ref: 'UserSchema'
		validate: [
			(value, done) ->
				true
			'post status only on a friend profile'
		]
	content:
		type: String
		trim: true
		required: true

module.exports = statusSchema
