'use strict'

StatusPackage =

	getRecentStatusForRequest: (req, res, id = null, data = {}) ->
		onProfile = id or req.data.at
		@getRecentStatus req, res, id, data, onProfile

	getRecentStatus: (req, res, id = null, data = {}, onProfile = false) ->
		next = _next = ->
			if data.recentStatus and data.chat
				if data.recentStatus.length < 3
					data.recentStatus.push
						_id: "5579d2f6aeb72cf06bd3fc27"
						at: null
						author:
							hashedId: null
							thumb50: '/img/wornet-thumb50.png'
							thumb90: '/img/wornet-thumb90.png'
							thumb200: '/img/wornet-thumb200.png'
							name:
								first: 'Vos premiers pas'
								last: ''
								full: 'Vos premiers pas'
							fullName: 'Vos premiers pas'
							present: false
							points: 0
						concernMe: false
						content: s("Les premiers statuts sont important... Qu'allez-vous poster ?  Un texte bien sympa du type \"Bonjour Wornet !\" ? Vos photos de vacances pour faire rêver vos premiers amis worners ? L'une des vidéos YouTube de la sitcom Warren Flamel inspiré de l'univers d'Harry Potter ?")
						date: new Date()
						status: 'active'
						images: []
						videos: [
							href: '//www.youtube.com/embed/5PC7v6jLQ_s'
							_id: "5579d2f6aeb72cf06bd3fc26"
						]
						links: []
						pointsValue: 0
				res.json data
		nextWithSession = ->
			req.session.save (err) ->
				warn err if err
				req.session.reload (err) ->
					warn err if err
					_next()
		unless data.chat
			ChatPackage.all req, (err, chat) ->
				if err
					warn err
				else
					data.chat = chat
					next()
		req.getFriends (err, friends, friendAsks) ->
			id = req.getRequestedUserId id
			connectedPeople = friends.column 'id'
			connectedPeopleAndMe = connectedPeople.copy()
			connectedPeopleAndMe.push req.user.id
			where = (if onProfile
				if config.wornet.onlyAuthoredByAFriend
					$or: [
						author:
							$in: connectedPeopleAndMe
							$ne: id
						at: id
					,
						author: id
						at: null
					]
				else
					$or: [
						at: id
					,
						author: id
						at: null
					]
			else
				author: $in: connectedPeopleAndMe
				at: $in: connectedPeopleAndMe.with [null]
			)
			if connectedPeopleAndMe.contains id
				Status.find where
					.skip 0
					.limit 100
					.sort date: 'desc'
					.select '_id date author at content status images videos links album albumName pointsValue'
					.exec (err, recentStatus) ->
						if err
							res.serverError err
						else
							missingIds = []
							recentStatusPublicData = []
							if recentStatus and typeof recentStatus is 'object'
								add = (val) ->
									val = strval val
									if val is 'undefined'
										throw new Error 'val must not be undefined'
									unless missingIds.contains val
										missingIds.push val
								recentStatus.each ->
									if @at
										add @at
									add @author
								searchInDataBase = !! config.wornet.onlyAuthoredByAFriend
								done = (err, usersMap) ->
									if err
										res.serverError err
									else
										recentStatus.each ->
											status = @toObject()
											if @at is @author
												@at = null
											status.author = usersMap[strval @author].publicInformations()
											if @at
												status.at = usersMap[strval @at].publicInformations()
											status.concernMe = [@at, @author].contains req.user.id, equals
											if status.concernMe and status.images.length and ! equals req.user.id, @author
												ids = status.images.column('src').map PhotoPackage.urlToId
												(req.session.photosAtMe ||= []).merge ids, 'add'
												next = nextWithSession
											status.status = @status
											if @status is 'blocked'
												status.content = ''
											recentStatusPublicData.push status
										data.recentStatus = recentStatusPublicData
										next()
								req.getUsersByIds missingIds, done #, searchInDataBase
							else
								data.recentStatus = recentStatusPublicData
								next()
			else
				warn [connectedPeopleAndMe, 'does not contains', id]
				res.serverError new PublicError s("Vous ne pouvez pas voir les statuts de ce profil")

	put: (req, res, done) ->
		@add req, (err, status, originalStatus) ->
			if err
				res.serverError err
			else
				albums = []
				count = status.images.length
				if count
					status.images.each ->
						photoId = PhotoPackage.urlToId @src
						PhotoPackage.publish req, photoId, status._id, (err, photo) ->
							if photo and ! albums.contains photo.album, equals
								albums.push photo.album
							unless --count
								if albums.length
									Album.find _id: $in: albums, (err, albums) ->
										if albums and albums.length
											if originalStatus
												originalStatus.album = albums[0]._id
												originalStatus.albumName = albums[0].name
												originalStatus.save()
											count = albums.length
											albums.each ->
												@refreshPreview (err) ->
													if err
														warn err
													unless --count
														done status
										else
											done status
								else
									done status
				else
					done status

	add: (req, done) ->
		if req.data.status
			try
				medias = req.data.medias || {}
				at = req.data.at || null
				unless at is null
					at = cesarRight at

				pointsValue = @calculatePoints medias, req.user.numberOfFriends

				Status.create
					author: req.user._id
					at: at
					content: req.data.status.content || ""
					images: medias.images || []
					videos: medias.videos || []
					links: medias.links || []
					pointsValue: pointsValue
				, (err, originalStatus) =>
					unless err

						status = originalStatus.toObject()
						status.author = req.user.publicInformations()

						next = (usersToNotify) ->
							place = status.author
							img = jd 'img(src=user.thumb50 alt=user.name.full data-id=user.hashedId data-toggle="tooltip" data-placement="top" title=user.name.full).thumb', user: place
							NoticePackage.notify usersToNotify, null,
								action: 'status'
								status: status
							NoticePackage.notify usersToNotify, null,
								action: 'notice'
								author: status.author
								forBestFriends: at is null
								notice: [
									img +
									jd 'span(data-href="/user/profile/' +
									place.hashedId + '/' + encodeURIComponent(place.name.full) + '#' + status._id + '") ' +
									if at is null
										s("{username} a publié un statut.", username: req.user.fullName)
									else
										s("{username} a publié un statut sur votre profil.", username: req.user.fullName)
								]
						at = status.at || null
						if at is null
							req.getFriends (err, friends, friendAsks) =>
								@updatePoints req, status, cesarRight(status.author.hashedId), true, next, friends.column '_id'
								#next friends.column '_id'
						else
							req.getUserById at, (err, user) =>
								status.at = if user
									user.publicInformations()
								else
									null
								@updatePoints req, status, cesarRight(status.author.hashedId), true, next, [at]
								#next [at]
					done err, status, originalStatus
			catch err
				done err
		else
			done new PublicError s("Ce statut est vide")

	calculatePoints: (medias, nbOfFriends) ->
		points = 1 #simple status
		if medias.images and medias.images.length > 0
			points = 2 #status with photo
		if medias.videos and medias.videos.length > 0
			points = 3 if points = 1 #status with video but without photo
			points = 4 if points = 2 #status with video and photo

		pointsToAdd = points * nbOfFriends

	updatePoints: (req, status, authorId, adding, done, param) ->
		id = authorId

		if !status
			new Error "status must not be undefined"

		pointsValue = status.pointsValue || 0

		User.findOne
			_id: id
		, (err, user) =>
			if err
				done err
			else if user
				if user.points or user.points is 0
					if adding
						newPoints = user.points + pointsValue
					else
						newPoints = user.points - pointsValue

					if newPoints < 0
						newPoints = 0

					req.user.points= newPoints
					req.session.user.points= newPoints
					User.update
						_id: id
					,
						points: newPoints
					, (err, user) ->
						if err
							done err
						else
							done param
				else
					@initPoints req, user, done, param

	initPoints: (req, user, done, param) ->
		newPoints = 0
		id = user.id
		Status.find
			author: id
		, (err, statusList) ->
			if err
				done err
			else
				for status in statusList
					medias = {images:status.images, videos:status.videos, links:status.links}

					if statusList.length is 1
						#The status just sent is the first one for that user
						#So there no need de init the points
						newPoints += StatusPackage.calculatePoints medias, req.user.numberOfFriends
					else
						#We calculate with 1 friend
						newPoints += StatusPackage.calculatePoints medias, 1

				req.user.points= newPoints
				req.session.user.points= newPoints
				User.update
					_id: id
				,
					points: newPoints
				, (err) ->
					if err
						done err
					else
						done param



module.exports = StatusPackage
