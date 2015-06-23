'use strict'

CommentPackage =

	put: (req, res, done) ->
		if req.data.status
			try
				medias = req.data.medias || {}
				hashedIdUser = req.user.hashedId
				at = if req.data.at
					req.data.at
				else if req.data.status and req.data.status.at and req.data.status.at.hashedId
					req.data.status.at.hashedId
				else null
				status = req.data.status
				Comment.create
					author: req.user._id
					content: req.data.comment.content || ""
					attachedStatus: status._id
					images: medias.images || []
					videos: medias.videos || []
					links: medias.links || []
				, (err, originalComment) =>
					unless err
						comment = originalComment.toObject()
						comment.author = req.user.publicInformations()
						hashedIdAuthor = status.author.hashedId
						usersToNotify = []
						unless equals hashedIdUser, hashedIdAuthor
							usersToNotify.push hashedIdAuthor
						unless [null, hashedIdAuthor, hashedIdUser].contains at
							usersToNotify.push at
						unless empty usersToNotify
							@notify usersToNotify, status, req.user, comment

						@getRecentCommentForRequest req, res, [status._id], (err, commentList) ->
							done err, commentList
			catch err
				done err
		else
			done new PublicError s("Ce commentaire ne concerne aucun statut")

	notify: (usersToNotify, status, commentator, comment) ->
		img = jd 'img(src=user.thumb50 alt=user.name.full data-id=user.hashedId data-toggle="tooltip" data-placement="top" title=user.name.full).thumb', user: commentator
		statusPlace = status.at || status.author
		commentatorsFriends = commentator.friends.column 'hashedId'
		for userToNotify in usersToNotify
			notice = if userToNotify is statusPlace.hashedId
				[
					img +
					jd 'span(data-href="/user/profile/' +
					statusPlace.hashedId + '/' + encodeURIComponent(statusPlace.name.full) + '#' + status._id + '") ' +
						s("{username} a commenté une publication de votre profil.", username: commentator.name.full)
				]
			else if userToNotify is status.author.hashedId and userToNotify isnt commentator.hashedId
				if commentatorsFriends.contains userToNotify
					[
						img +
						jd 'span(data-href="/user/profile/' +
						statusPlace.hashedId + '/' + encodeURIComponent(statusPlace.name.full) + '#' + status._id + '") ' +
							s("{username} a commenté votre publication.", username: commentator.name.full)
					]
				else
					[
						img +
						jd 'span(data-href="/user/profile/' +
						statusPlace.hashedId + '/' + encodeURIComponent(statusPlace.name.full) + '#' + status._id + '") ' +
							s("{username}, ami de {placename}, a commenté votre publication.", {username: commentator.name.full, placename:statusPlace.name.full })
					]
			else
				null

			if notice
				notice.push 'comment', commentator._id, status._id
				NoticePackage.notify [cesarRight userToNotify], null,
					action: 'notice'
					author: commentator
					notice: notice

		otherCommentators = []
		if status.comments
			for comment in status.comments
				if ![status.author.hashedId, status.at.hashedId].contains(comment.author.hashedId) and !otherCommentators.contains(comment.author.hashedId)
					otherCommentators.push comment.author.hashedId

			notice = [
					img +
					jd 'span(data-href="/user/profile/' +
					statusPlace.hashedId + '/' + encodeURIComponent(statusPlace.name.full) + '#' + status._id + '") ' +
						s("{username} a également commenté une publication.", username: commentator.name.full)
				]

			unless otherCommentators.length > 0
				otherCommentatorsIds = otherCommentators.map (value) ->
					cesarRight value
				NoticePackage.notify otherCommentatorsIds, null,
					action: 'notice'
					author: commentator
					notice: notice

		userstoPushComment = otherCommentators
				.concat usersToNotify
        		.unique()
        		.map (value) ->
            		cesarRight value

		NoticePackage.notify userstoPushComment, null,
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
									comment.isMine = equals @author, req.user._id
									for status in statusList
										if equals status._id, @attachedStatus
											comment.attachedStatus = status
											comment.onMyWall = equals status.at, req.user._id
											break
									comment.author = usersMap[comment.author].publicInformations()
									result[comment.attachedStatus._id] ||= []
									result[comment.attachedStatus._id].push comment
								done null, commentList: result
				else
					done null, commentList: {}
		else
			res.notFound()

module.exports = CommentPackage
