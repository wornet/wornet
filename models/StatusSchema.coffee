'use strict'

statusSchema = BaseSchema.extend
	date:
		type: Date
		default: Date.now
		required: true
	author:
		type: ObjectId
		ref: 'UserSchema'
	content:
		type: String
		trim: true
		required: true

module.exports = statusSchema
