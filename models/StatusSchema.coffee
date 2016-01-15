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
	shares: [
		type: ObjectId
		ref: 'StatusSchema'
	]
	isAShare:
		type: Boolean
		default: false
	referencedStatus:
		type: ObjectId
		ref: 'StatusSchema'

statusSchema.path('content').validate (text) ->
	text.length < config.wornet.limits.realStatusLength

statusSchema.methods.isEmpty = ->
	empty(@content) and empty(@images) and empty(@videos) and empty(@links)

statusSchema.methods.populateUsers = (done) ->
	statusToReturn = @toObject()
	usersToFind = []
	usersToFind.push(@author) if !empty(@author)
	usersToFind.push(@at) if !empty(@at)
	if usersToFind.length
		User.find
			_id: $in: usersToFind
		, (err, users) =>
			for user in users
				if equals user._id, @author
					statusToReturn.author = user.publicInformations()
				else if equals user._id, @at
					statusToReturn.at = user.publicInformations()
			done statusToReturn
	else
		done statusToReturn

statusSchema.pre 'save', (next) ->
	if @isEmpty() and !@isAShare
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
	], [
		PlusW
		status: @id
	], [
		Notice
		attachedStatus: @id
	], next


module.exports = statusSchema
