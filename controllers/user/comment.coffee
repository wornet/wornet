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
		if req.data.comment and req.data.comment._id
			Comment.remove
				_id: req.data.comment._id
			, (err) ->
				if err
					res.serverError err
				else
					res.json()
		else
			res.serverError 'No comment to Remove'

	router.post '', (req, res) ->
		if req.data.comment and req.data.comment._id
			Comment.update
				_id: req.data.comment._id
			,
				content: req.data.comment.content || ''
			, (err, comment) ->
				if err
					res.serverError err
				else
					CommentPackage.getRecentCommentForRequest req, res, [req.data.comment.attachedStatus._id], commentListResponse.bind res
		else
			res.serverError 'No comment to Update'
