'use strict'

CommentPackage =

	put: (req, res, done) ->
		if req.data.status
			try
				StatusPackage.getOriginalStatus req.data.status, (err, status) =>
					warn err if err
					medias = req.data.medias || {}
					hashedIdUser = req.user.hashedId
					at = if req.data.at
						req.data.at
					else if status and status.at and status.at.hashedId
						status.at.hashedId
					else null
					req.getFriends (err, friends) =>
						warn err if err
						newAt = at || status.author.hashedId
						isAPublicAccount req, newAt, true, (err, isAPublicAccount) =>
							UserPackage.refreshFollows req, =>
								if !friends.column('_id').map(cesarLeft).contains(newAt) and newAt isnt hashedIdUser and (!isAPublicAccount and !req.user.followings.map(cesarLeft).contains newAt, equals)
									res.serverError new PublicError s("Vous ne pouvez commenter que chez vos amis ou abonnements.")
								else
									Comment.create
										author: req.user._id
										content: req.data.comment.content || ""
										attachedStatus: status._id
										images: medias.images || []
										videos: medias.videos || []
										links: medias.links || []
									, (err, originalComment) =>
										warn err if err
										unless err
											comment = originalComment.toObject()
											comment.author = req.user.publicInformations()
											hashedIdAuthor = status.author.hashedId
											usersToNotify = []
											unless equals hashedIdUser, hashedIdAuthor
												if !status.author.accountConfidentiality is "public" or req.user.friends.column('hashedId').contains hashedIdAuthor
													usersToNotify.push hashedIdAuthor
											unless [null, hashedIdAuthor, hashedIdUser].contains at
												if status.at and !status.at.accountConfidentiality is "public" or req.user.friends.column('hashedId').contains at
													usersToNotify.push at
											@propagate comment, at || hashedIdAuthor

											@notify usersToNotify, status, req.user, comment

											@getRecentCommentForRequest req, res, [status._id], done
			catch err
				done err
		else
			done new PublicError s("Ce commentaire ne concerne aucun statut")

	notify: (usersToNotify, status, commentator, originalComment) ->
		img = jd 'img(src=user.thumb50 alt=user.name.full data-id=user.hashedId data-toggle="tooltip" data-placement="top" title=user.name.full).thumb', user: commentator
		statusPlace = status.at || status.author
		generateNotice = (text) ->
			[
				img +
				jd 'span(data-href="/user/status/' + status._id + '") ' +
					text
			]
		commentatorsFriends = commentator.friends.column 'hashedId'
		for userToNotify in usersToNotify
			notice = if userToNotify is statusPlace.hashedId
				generateNotice s("{username} a commenté une publication de votre profil.", username: commentator.name.full)
			else if userToNotify is status.author.hashedId and userToNotify isnt commentator.hashedId
				generateNotice if commentatorsFriends.contains userToNotify
					s("{username} a commenté votre publication.", username: commentator.name.full)
				else
					s("{username}, ami de {placename}, a commenté votre publication.", {username: commentator.name.full, placename:statusPlace.name.full })
			else
				null

			if notice
				notice.push 'comment', commentator._id, status._id, cesarRight statusPlace.hashedId
				NoticePackage.notify [cesarRight userToNotify], null,
					action: 'notice'
					author: commentator
					notice: notice

		if status.comments
			otherCommentators = []
			for comment in status.comments
				if ![status.author.hashedId, status.at.hashedId, commentator.hashedId].contains(comment.author.hashedId) and !otherCommentators.contains(comment.author.hashedId)
					if !comment.author.accountConfidentiality is "public" or commentator.friends.column('hashedId').contains comment.author.hashedId
						otherCommentators.push comment.author.hashedId

			notice = generateNotice s("{username} a également commenté une publication.", username: commentator.name.full)

			if otherCommentators.length > 0
				otherCommentatorsIds = otherCommentators.map cesarRight
				notice.push 'othercomments', commentator._id, status._id, cesarRight statusPlace.hashedId
				NoticePackage.notify otherCommentatorsIds, null,
					action: 'notice'
					author: commentator
					notice: notice

	propagate: (comment, place) ->
		NoticePackage.notifyPlace place, null,
			action: 'comment'
			comment: comment

	getRecentCommentForRequest: (req, res, statusIds, done) ->
		if statusIds
			Comment.find
				attachedStatus: $in: statusIds
			.sort date: 'asc'
			.exec (err, comments) ->
				if err
					res.serverError err
				else if comments
					authorIds = comments.column('author').unique()
					Status.find
						_id: $in: statusIds
					, (err, statusList) ->
						req.getUsersByIds authorIds, (err, usersMap) ->
							if err
								res.serverError err
							else
								result = {}
								comments.each ->
									comment = @toObject()
									comment.isMine = if req.user
										equals @author, req.user._id
									else
										false
									for status in statusList
										if equals status._id, @attachedStatus
											comment.attachedStatus = status
											statusAt = status.at || status.author
											comment.onMyWall = if req.user
												equals statusAt, req.user._id
											else
												false
											break
									comment.author = usersMap[comment.author].publicInformations()
									(result[comment.attachedStatus._id] ||= []).push comment
								done null, commentList: result
				else
					done null, commentList: {}
		else
			res.notFound()

module.exports = CommentPackage
