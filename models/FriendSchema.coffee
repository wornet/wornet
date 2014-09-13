'use strict'

status = [
	'waiting'
	'accepted'
	'refused'
	'blocked'
]

friendSchema = new Schema
	askedFrom:
		type: ObjectId
		ref: 'UserSchema'
	askedTo:
		type: ObjectId
		ref: 'UserSchema'
	status:
		type: String
		default: status[0]
		enum: status
,
	toObject:
		virtuals: true
	toJSON:
		virtuals: true

status.forEach (st) ->
	friendSchema.virtual(st).get ->
		@status is st

friendSchema.virtual('createdAt').get ->
	Date.fromId @_id

module.exports = friendSchema
