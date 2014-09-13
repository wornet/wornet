'use strict'

status = [
	'unread'
	'read'
]

messageRecipientSchema = new Schema
	message:
		type: ObjectId
		ref: 'MessageSchema'
	recipient:
		type: ObjectId
		ref: 'UserSchema'
	status:
		type: String
		enum: status

status.forEach (st) ->
	messageRecipientSchema.virtual(st).get ->
		@status is st

module.exports = messageRecipientSchema