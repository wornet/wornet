'use strict'

CommentPackage =

	put: (req, res, done) ->
		if req.data.status
			try
				medias = req.data.medias || {}
				at = req.data.at || null
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

						usersToNotify = []
						if comment.author.hashedId isnt status.author.hashedId
							usersToNotify.push status.author.hashedId
						unless [null, status.author.hashedId, comment.author.hashedId].contains at
							usersToNotify.push at

						unless empty usersToNotify
							req.getFriends (err, friends, friendAsks) =>
								@notify usersToNotify, friends.column('_id'), comment, status, at


						@getRecentCommentForRequest req, res, [status._id], (err, commentList) ->

						# commentsPublicData = []
						# Comment.find
						# 	attachedStatus: status._id
						# , (err, commentList) ->
						# 	authors = commentList.column 'author'
						# 	next = (err, usersMap) ->
						# 		if err
						# 			res.serverError err
						# 		else
						# 			commentList.each ->
						# 				comment = @toObject()
						# 				comment.author = usersMap[strval @author].publicInformations()
						# 				commentsPublicData.push comment
									done err, commentList
							# req.getUsersByIds authors, next
			catch err
				done err
		else
			done new PublicError s("Ce commentaire ne concerne aucun statut")

	notify: (usersToNotify, friendIds, comment, status, at) ->
		img = jd 'img(src=user.thumb50 alt=user.name.full data-id=user.hashedId data-toggle="tooltip" data-placement="top" title=user.name.full).thumb', user: comment.author

		statusPlace = status.at || status.author
		NoticePackage.notify usersToNotify, null,
			action: 'comment'
			comment: comment
		NoticePackage.notify usersToNotify, null,
			action: 'notice'
			author: comment.author
			notice: [
				img +
				jd 'span(data-href="/user/profile/' +
				statusPlace.hashedId + '/' + encodeURIComponent(statusPlace.name.full) + '#' + status._id + '") ' +
					s("{username} a publié un commentaire.", username: comment.author.name.full)
			]

		friendIds = friendIds.filter (friendId) ->
			friendId and /^[0-9a-f]+$/ig.test(friendId) and ! [at, status.author.id].contains friendId, equals
		.map strval

		statusPlaceId = cesarRight statusPlace.hashedId
		if /^[0-9a-f]+$/ig.test statusPlaceId
			Friend.find
				status: 'accepted'
				$or: [
					askedFrom: $in: friendIds
					askedTo: statusPlaceId
				,
					askedTo: $in: friendIds
					askedFrom: statusPlaceId
				], (err, friends) ->
					if err
						warn err
					if friends
						usersToNotify = friends.map (friend) ->
							if equals friend.askedTo, statusPlace
								friend.askedFrom
							else
								friend.askedTo

						NoticePackage.notify usersToNotify, null,
							action: 'notice'
							author: comment.author
							forBestFriends: true
							notice: [
								img +
								jd 'span(data-href="/user/profile/' +
								encodeURIComponent(statusPlace.hashedId) +
								'/' + encodeURIComponent(statusPlace.name.full) + '#' +
								encodeURIComponent(status._id) + '") ' +
									s("{username} a publié un commentaire.", username: comment.author.name.full)
							]

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
