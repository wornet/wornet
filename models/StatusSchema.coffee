'use strict'

statusSchema = PostSchema.extend
	at:
		type: ObjectId
		ref: 'UserSchema'
	album:
		type: ObjectId
		ref: 'AlbumSchema'
	albumName:
		type: String
	pointsValue:
		type: Number

statusSchema.path('content').validate (text) ->
	text.length < config.wornet.limits.realStatusLength

statusSchema.methods.isEmpty = ->
	empty(@content) and empty(@images) and empty(@videos) and empty(@links)

statusSchema.pre 'save', (next) ->
	if @isEmpty()
		next new PublicError s("Ce statut est vide")
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
							next new PublicError s("Vous ne pouvez poster que sur les profils de vos amis")

statusSchema.pre 'remove', (next) ->
	PhotoPackage.deleteImages @images
	parallelRemove [
		Comment
		attachedStatus: @id
	,
		PlusW
		status: @id
	], next


module.exports = statusSchema
