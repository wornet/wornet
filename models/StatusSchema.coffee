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
	images: [
		name:
			type: String
			trim: true
		src:
			type: String
			trim: true
	]
	videos: [
		href:
			type: String
			trim: true
	]
	links: [
		href:
			type: String
			trim: true
		https: Boolean
	]

statusSchema.pre 'save', (next) ->
	if empty(@content) and empty(@images) and empty(@videos) and empty(@links)
		next new Error s("Ce statut est vide")
	else
		if equals @at, @author
			@at = null
		if @at is null
			next()
		else
			at = strval @at
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
							next new Error s("Vous ne pouvez poster que sur les profils de vos amis")


module.exports = statusSchema
