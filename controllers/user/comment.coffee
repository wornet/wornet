'use strict'

module.exports = (router) ->

	router.put '/add', (req, res) ->
		CommentPackage.put req, res, (err, status) ->
			if err
				res.serverError err
			else
				res.json status
			#CommentPackage.getRecentCommentsForRequest req, res, status

	router.get '', (req, res) ->
		if req.data.statusIds
			Comment.find
				attachedStatus: $in: req.data.statusIds
			, (err, comments) ->
				if err
					res.serverError err
				else if comments
					authorIds = comments.column('author').unique()
					req.getUsersByIds authorIds, (err, usersMap) ->
						if err
							res.serverError err
						else
							result = {}
							comments.each (id) ->
								comment = @toObject()
								comment.author = usersMap[comment.author].publicInformations()
								result[comment.attachedStatus] ||= []
								result[comment.attachedStatus].push comment
							res.json commentList: result
				else
					res.json()
		else
			res.notFound()
