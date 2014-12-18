'use strict'

commentSchema = PostSchema.extend
	status:
		type: ObjectId
		ref: 'StatusSchema'
		required: true

commentSchema.pre 'save', (next) ->
	if empty(@content) and empty(@images) and empty(@videos) and empty(@links)
		next new PublicError s("Ce commentaire est vide")
	else
		Status.findById @status, (err, status) ->
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


module.exports = commentSchema
