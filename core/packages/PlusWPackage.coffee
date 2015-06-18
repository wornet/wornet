'use strict'

PlusWPackage =

	put: (req, res, end) ->

		statusReq = req.data.status
		idStatus = req.data.status._id
		idUser = req.user._id
		if req.data.at
			at = cesarRight req.data.at
		else
			at = null
		parallel [(done) ->
			PlusW.create
				user: idUser
				status: idStatus
			, done
		, (done) =>
			Status.findOne
				_id: idStatus
			, (err, status) =>
				if err
					done err
				if !status.nbLike
					newNbLike = 1
				else
					newNbLike = status.nbLike + 1

				Status.update
					_id: idStatus
				,
					nbLike: newNbLike
				, (err) =>
					if err
						done err
					else
						usersToNotify = []
						idAuthor = cesarRight statusReq.author.hashedId
						if strval(idUser) isnt strval(idAuthor)
							usersToNotify.push idAuthor
						unless [null, idAuthor, idUser].contains at, equals
							usersToNotify.push at

						unless empty usersToNotify
								@notify usersToNotify, statusReq, req.user
						end null, {'newNbLike': newNbLike}
		], ->
			res.json()
		, ->
			res.serverError err

	delete: (req, res, done) ->
		idStatus = req.data.status._id
		idUser = req.user._id
		parallel [(done) ->
			PlusW.remove
				user: idUser
				status: idStatus
			, (err) ->
		, (done) ->
			Status.findOne
				_id: idStatus
			, (err, status) ->
				if err
					res.serverError err
				if !status.nbLike
					newNbLike = 0
				else
					newNbLike = status.nbLike - 1
				Status.update
					_id: idStatus
				,
					nbLike: newNbLike
				, (err, status) ->
					if err
						res.serverError err
					else
						NoticePackage.unnotify
							action: 'notice'
							notice:
								type: 'like'
								launcher: idUser
								status: idStatus
						res.json {'newNbLike': newNbLike}
		], ->
			res.json()
		, ->
			res.serverError err

	notify: (usersToNotify, status, liker) ->

		img = jd 'img(src=user.thumb50 alt=user.name.full data-id=user.hashedId data-toggle="tooltip" data-placement="top" title=user.name.full).thumb', user: liker

		statusPlace = status.at || status.author
		likersFriends = liker.friends.column 'hashedId'
		for userToNotify in usersToNotify

			if cesarLeft(userToNotify) is statusPlace.hashedId
				notice = [
					img +
					jd 'span(data-href="/user/profile/' +
					statusPlace.hashedId + '/' + encodeURIComponent(statusPlace.name.full) + '#' + status._id + '") ' +
						s("{username} a aimé une publication de votre profil.", username: liker.name.full)
				]
			else if cesarLeft(userToNotify) is status.author.hashedId and likersFriends.contains cesarLeft(userToNotify)
				notice = [
					img +
					jd 'span(data-href="/user/profile/' +
					statusPlace.hashedId + '/' + encodeURIComponent(statusPlace.name.full) + '#' + status._id + '") ' +
						s("{username} a aimé votre publication.", username: liker.name.full)
				]
			else if cesarLeft(userToNotify) is status.author.hashedId and !likersFriends.contains cesarLeft(userToNotify)
				notice = [
					img +
					jd 'span(data-href="/user/profile/' +
					statusPlace.hashedId + '/' + encodeURIComponent(statusPlace.name.full) + '#' + status._id + '") ' +
						s("{username}, ami de {placename}, a aimé votre publication.", {username: liker.name.full, placename:statusPlace.name.full })
				]

			notice.push 'like'
			notice.push liker._id
			notice.push status._id

			NoticePackage.notify [userToNotify], null,
				action: 'notice'
				author: liker
				notice: notice

module.exports = PlusWPackage
