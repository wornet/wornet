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
		me = req.user.id
		userComment = req.data.comment
		if userComment and userComment._id
			Comment.findOne
				_id: userComment._id
			, (err, comment) ->
				if err
					res.serverError err
				else if !comment
					res.serverError 'No comment to Remove'
				else
					if comment.attachedStatus
						Status.findOne
							_id: comment.attachedStatus
						, (err, status) ->
							if err
								res.serverError err
							else if !status
								res.serverError 'No status on comment'
							else
								if [comment.author, status.at].contains me, equals
									Comment.remove
										_id: userComment._id
									, (err) ->
										if err
											res.serverError err
										else
											res.json()
								else
									res.serverError "You don't have the right to remove this comment"
					else
						res.serverError 'No status on comment'

	router.post '', (req, res) ->
		userComment = req.data.comment
		me = req.user.id
		if userComment and userComment._id
			Comment.update
				_id: userComment._id
				author: me
			,
				content: userComment.content || ''
			, (err, comment) ->
				if err
					res.serverError err
				else if !comment
					res.serverError "You don't have the right to update this comment"
				else
					CommentPackage.getRecentCommentForRequest req, res, [userComment.attachedStatus._id], commentListResponse.bind res
		else
			res.serverError 'No comment to Update'
