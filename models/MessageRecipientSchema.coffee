'use strict'

status = [
	'unread'
	'read'
]

messageRecipientSchema = BaseSchema.extend
	message:
		type: ObjectId
		ref: 'MessageSchema'
	recipient:
		type: ObjectId
		ref: 'UserSchema'
	status:
		type: String
		enum: status
		default: status[0]

status.forEach (st) ->
	messageRecipientSchema.virtual(st).get ->
		@status is st

messageRecipientSchema.pre 'remove', (next) ->
	parallelRemove [
		Message
		id: @message
	], next

module.exports = messageRecipientSchema
