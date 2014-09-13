'use strict'

messageSchema = new Schema
	author:
		type: ObjectId
		ref: 'UserSchema'
	content:
		type: String
		trim: true
		required: true

messageSchema.virtual('createdAt').get ->
	Date.fromId @_id

module.exports = messageSchema