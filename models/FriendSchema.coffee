'use strict'

status = [
	'waiting'
	'accepted'
	'refused'
	'blocked'
]

friendSchema = BaseSchema.extend
	askedFrom:
		type: ObjectId
		ref: 'UserSchema'
		required: true
	askedTo:
		type: ObjectId
		ref: 'UserSchema'
		required: true
	status:
		type: String
		default: status[0]
		enum: status
		required: true
,
	toObject:
		virtuals: true
	toJSON:
		virtuals: true

status.each ->
	s = @
	friendSchema.methods['is' + ucfirst(s)] = ->
		@status = s


module.exports = friendSchema
