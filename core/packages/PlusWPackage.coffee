'use strict'

PlusWPackage =

	put: (req, res, end) ->
		statusReq = req.data.status
		idStatus = req.data.status._id
		hashedIdUser = req.user.hashedId
		at = if req.data.at
			req.data.at
		else if req.data.status and req.data.status.at and req.data.status.at.hashedId
			req.data.status.at.hashedId
		else null

		@checkRights req, res, req.data.status, true, (err, ok) =>
			if ok
				parallel
					plusW: (done) ->
						PlusW.create
							user: req.user._id
							status: idStatus
						, done
					newNbLike: (done) =>
						Status.findOneAndUpdate
							_id: idStatus
						,
							$inc: nbLike: 1
						, (err, status) =>
							if err
								done err
							else
								usersToNotify = []
								hashedIdAuthor = statusReq.author.hashedId
								#usersToNotify contains hashedIds tests in notify.
								#It will be transformed just before NoticePackage calling
								unless equals hashedIdUser, hashedIdAuthor
									usersToNotify.push hashedIdAuthor
								unless [null, hashedIdAuthor, hashedIdUser].contains at
									usersToNotify.push at
								unless empty usersToNotify
									@notify usersToNotify, statusReq, req.user
								done null, status.nbLike
				, (result) ->
					end null, result.newNbLike
				, end
			else
				end err, 0

	delete: (req, res, end) ->
		idStatus = req.data.status._id
		idUser = req.user._id
		@checkRights req, res, req.data.status, false, (err, ok) =>
			if ok
				parallel
					plusW: (done) ->
						PlusW.remove
							user: idUser
							status: idStatus
						, done
					newNbLike: (done) ->
						Status.findOneAndUpdate
							_id: idStatus
						,
							$inc: nbLike: -1
						, (err, status) ->
							if err
								done err
							else
								NoticePackage.unnotify
									action: 'notice'
									notice:
										type: 'like'
										launcher: idUser
										status: idStatus
								done null, status.nbLike
				, (result) ->
					end null, result.newNbLike
				, end
			else
				end err, 0

	checkRights: (req, res, status, liking, done) ->
		req.getFriends (err, friends, friendAsks) ->
			friendsList = friends.column('_id')
			friendsList.push req.user._id
			idStatus = status._id
			#The status is owned by one of my friends or on his wall
			whereStatus =
				_id: idStatus
				$or: [
					author: $in: friendsList
				,
					at: $in: friendsList
				]
			Status.findOne whereStatus
			, (err, result) ->
				if err
					done err, false
				else if !result
					done new PublicError s("Vous n'avez accès à ce statut"), false
				else
					wherePlus =
						user: req.user._id
						status: idStatus
					PlusW.findOne wherePlus
					, (err, plusw) ->
						if err
							done err, false
						if (liking and !plusw) or (!liking and plusw)
							done null, true
						else
							done null, false

	notify: (usersToNotify, status, liker) ->

		img = jd 'img(src=user.thumb50 alt=user.name.full data-id=user.hashedId data-toggle="tooltip" data-placement="top" title=user.name.full).thumb', user: liker
		statusPlace = status.at || status.author
		generateNotice = (text) ->
			[
				img +
				jd 'span(data-href="/user/profile/' +
				statusPlace.hashedId + '/' + encodeURIComponent(statusPlace.name.full) + '#' + status._id + '") ' +
					text
			]
		likersFriends = liker.friends.column 'hashedId'
		for userToNotify in usersToNotify
			notice = if userToNotify is statusPlace.hashedId
				generateNotice s("{username} a aimé une publication de votre profil.", username: liker.name.full)
			else if userToNotify is status.author.hashedId and userToNotify isnt liker.hashedId
				generateNotice if likersFriends.contains userToNotify
					s("{username} a aimé votre publication.", username: liker.name.full)
				else
					s("{username}, ami de {placename}, a aimé votre publication.", {username: liker.name.full, placename:statusPlace.name.full })
			else
				null

			if notice
				notice.push 'like', liker._id, status._id
				NoticePackage.notify [cesarRight userToNotify], null,
					action: 'notice'
					author: liker
					notice: notice

module.exports = PlusWPackage
