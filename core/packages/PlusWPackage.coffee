'use strict'

PlusWPackage =

	put: (req, res, end) ->

		statusReq = req.data.status
		idStatus = req.data.status._id
		idUser = req.user._id
		at = if req.data.at
			cesarRight req.data.at
		else
			null
		parallel
			plusW: (done) ->
				PlusW.create
					user: idUser
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
						idAuthor = cesarRight statusReq.author.hashedId
						if strval(idUser) isnt strval(idAuthor)
							usersToNotify.push idAuthor
						unless [null, idAuthor, idUser].contains at, equals
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
