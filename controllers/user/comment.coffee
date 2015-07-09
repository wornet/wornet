'use strict'

commentListResponse = (err, commentList) ->
	if err
		@serverError err
	else
		@json commentList

module.exports = (router) ->

	router.put '/add', (req, res) ->
		CommentPackage.put req, res, commentListResponse.bind res

	router.get '', (req, res) ->
		CommentPackage.getRecentCommentForRequest req, res, req.data.statusIds, commentListResponse.bind res

	router.delete '', (req, res) ->
		comment = req.data.comment
		me = req.user.id
		hashedMe = req.user.hashedId
		if comment and comment._id and comment.author and comment.attachedStatus
			if comment.author.hashedId is hashedMe || comment.attachedStatus.at is me
				Comment.remove
					_id: req.data.comment._id
				, (err) ->
					if err
						res.serverError err
					else
						res.json()
			else
				res.serverError "You don't have the right to remove this comment"
		else
			res.serverError 'No comment to Remove'

	router.post '', (req, res) ->
		origComment = req.data.comment
		hashedMe = req.user.hashedId
		if origComment and origComment.author and origComment._id
			if origComment.author.hashedId is hashedMe
				Comment.update
					_id: origComment._id
				,
					content: origComment.content || ''
				, (err, comment) ->
					if err
						res.serverError err
					else
						CommentPackage.getRecentCommentForRequest req, res, [origComment.attachedStatus._id], commentListResponse.bind res
			else
				res.serverError "You don't have the right to update this comment"
		else
			res.serverError 'No comment to Update'
