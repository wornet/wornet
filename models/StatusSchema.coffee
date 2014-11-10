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
	if equals @at, @author
		@at = null
	console.log @at
	if @at is null
		next()
	else
		at = strval @at
		User.findById @author, (err, user) ->
			if err
				next err
			else
				user.getFriends (err, friends) ->
					console.log [friends, at]
					if err
						next err
					else if friends.has(id: at)
						next()
					else
						next new Error 'post status only on a friend profile'


module.exports = statusSchema
