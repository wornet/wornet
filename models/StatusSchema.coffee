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
	content:
		type: String
		trim: true
		required: true

statusSchema.pre 'save', (next) ->
	author = @author
	at = @at
	User.findById @author, (err, user) ->
		if err
			next err
		else
			user.getFriends (err, friends) ->
				if err
					next err
				else if friends.has(id: at)
					next()
				else
					next new Error 'post status only on a friend profile'


module.exports = statusSchema
