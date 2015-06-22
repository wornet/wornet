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
						unless equals hashedIdUser, hashedIdAuthor
							usersToNotify.push hashedIdAuthor
						unless [null, hashedIdAuthor, hashedIdUser].contains at, equals
							usersToNotify.push at
						unless empty usersToNotify
							@notify usersToNotify, statusReq, req.user
						done null, status.nbLike
		, (result) ->
			end null, result.newNbLike
		, end

	delete: (req, res, end) ->
		idStatus = req.data.status._id
		idUser = req.user._id
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

	notify: (usersToNotify, status, liker) ->

		img = jd 'img(src=user.thumb50 alt=user.name.full data-id=user.hashedId data-toggle="tooltip" data-placement="top" title=user.name.full).thumb', user: liker
		statusPlace = status.at || status.author
		likersFriends = liker.friends.column 'hashedId'
		for userToNotify in usersToNotify
			notice = if userToNotify is statusPlace.hashedId
				[
					img +
					jd 'span(data-href="/user/profile/' +
					statusPlace.hashedId + '/' + encodeURIComponent(statusPlace.name.full) + '#' + status._id + '") ' +
						s("{username} a aimé une publication de votre profil.", username: liker.name.full)
				]
			else if userToNotify is status.author.hashedId and userToNotify isnt liker.hashedId
				if likersFriends.contains userToNotify
					[
						img +
						jd 'span(data-href="/user/profile/' +
						statusPlace.hashedId + '/' + encodeURIComponent(statusPlace.name.full) + '#' + status._id + '") ' +
							s("{username} a aimé votre publication.", username: liker.name.full)
					]
				else
					[
						img +
						jd 'span(data-href="/user/profile/' +
						statusPlace.hashedId + '/' + encodeURIComponent(statusPlace.name.full) + '#' + status._id + '") ' +
							s("{username}, ami de {placename}, a aimé votre publication.", {username: liker.name.full, placename:statusPlace.name.full })
					]
			else
				null

			if notice
				notice.push 'like', liker._id, status._id
				NoticePackage.notify [cesarRight userToNotify], null,
					action: 'notice'
					author: liker
					notice: notice

module.exports = PlusWPackage
