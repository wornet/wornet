'use strict'

StatusPackage =

	getRecentStatusForRequest: (req, res, id = null, data = {}, updatedAt = null) ->
		onProfile = id or req.data.at
		@getRecentStatus req, res, id, data, onProfile, updatedAt

	getRecentStatus: (req, res, id = null, data = {}, onProfile = false, updatedAt = null) ->
		id = req.getRequestedUserId id
		next = _next = =>
			if data.recentStatus and data.chat
				if (! onProfile or equals id, req.user._id) and ! req.user.firstStepsDisabled and data.recentStatus.length < 3
					data.recentStatus.push @defaultStatus()

				if res.endAt
					warn JSON.stringify(res.endAt, true, 2) + JSON.stringify data, true, 2
				else
					res.json data
		nextWithSession = ->
			req.session.save (err) ->
				warn err if err
				req.session.reload (err) ->
					warn err if err
					_next()
		unless data.chat
			updatedAt *= 1
			# to prevent duplicate the last message from which the updatedAt is extracted
			updatedAt += 1000
			where = if updatedAt
				_objectId = Math.floor(updatedAt / 1000).toString(16) + '0000000000000000'
				if /^[0-9a-fA-F]{24}$/.test _objectId
					_id: $gt: new ObjectId(_objectId).path
				else
					{}
			else
				{}
			ChatPackage.where req, where, (err, chat) ->
				if err
					warn err
				else
					data.chat = chat
					next()
		req.getFriends (err, friends, friendAsks) =>
			connectedPeople = friends.column 'id'
			connectedPeopleAndMe = connectedPeople.with req.user.id
			where = @where id, connectedPeopleAndMe, onProfile
			limit = config.wornet.limits.statusPageCount
			if req.data.offset
				limit = config.wornet.limits.scrollStatusPageCount
				_objectId = req.data.offset
				if /^[0-9a-fA-F]{24}$/.test _objectId
					where._id = $lt: new ObjectId(_objectId).path
			if connectedPeopleAndMe.contains id
				Status.find where
					.skip 0
					.limit limit
					.sort date: 'desc'
					.select '_id date author at content status images videos links album albumName pointsValue nbLike'
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
										idsStatus = recentStatus.column '_id'
										likedStatus = {}
										PlusW.find
											status: $in: idsStatus
										, (err, result) ->
											tabLike = []
											for idStatus in idsStatus
												tabLike[idStatus] ||= {likedByMe: false, nbLike: 0}
											for like in result
												tabLike[like.status].nbLike++
												if equals req.user.id, like.user
													tabLike[like.status].likedByMe = true

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
												status.likedByMe = tabLike[status._id].likedByMe
												status.nbLike = tabLike[status._id].nbLike
												status.nbImages = status.images.length
												if status.images.length
													status.images = [status.images[0]]
													if -1 isnt status.images[0].src.indexOf "200x"
														status.images[0].src = status.images[0].src.replace "200x", ""
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

	where: (id, connectedPeopleAndMe, onProfile) ->
		if onProfile
			$or: [
				at: id
				.with if config.wornet.onlyAuthoredByAFriend
					author:
						$in: connectedPeopleAndMe
						$ne: id
			,
				author: id
				at: null
			]
		else
			author: $in: connectedPeopleAndMe
			at: $in: connectedPeopleAndMe.with [null]

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
											albums.each (key, album) ->
												req.getUserById album.user, (err, user) =>
													UserAlbums.touchAlbum user || req.user, @_id, (err, result) ->
														if err
															warn err
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

						next = (usersToNotify) =>
							place = status.at or status.author
							status.nbImages = status.images.length
							if status.images.length
								status.images = [status.images[0]]
								if -1 isnt status.images[0].src.indexOf "200x"
									status.images[0].src = status.images[0].src.replace "200x", ""
							@propagate status
							img = jd 'img(src=user.thumb50 alt=user.name.full data-id=user.hashedId data-toggle="tooltip" data-placement="top" title=user.name.full).thumb', user: status.author
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
								, 'status', req.user._id, status._id, cesarRight place.hashedId
								]
						at = status.at || null
						if at is null
							req.getFriends (err, friends, friendAsks) =>
								@updatePoints req, status, cesarRight(status.author.hashedId), true, (err) ->
									if err
										done err
									else
										next friends.column '_id'
						else
							req.getUserById at, (err, user) =>
								status.at = if user
									user.publicInformations()
								else
									null
								@updatePoints req, status, cesarRight(status.author.hashedId), true, (err) ->
									if err
										done err
									else
										next [at]
					done err, status, originalStatus
			catch err
				done err
		else
			done new PublicError s("Ce statut est vide")

	propagate: (status) ->
		place = status.at or status.author
		place = place.hashedId or place
		status.nbLike = 0
		status.nbComment = 0
		NoticePackage.notifyPlace place, null,
			action: 'status'
			status: status


	calculatePoints: (medias, nbOfFriends) ->
		points = 1 # simple status
		if medias.images and medias.images.length > 0
			points = 2 # status with photo
		if medias.videos and medias.videos.length > 0
			points = 3 if points is 1 # status with video but without photo
			points = 4 if points is 2 # status with video and photo

		pointsToAdd = points * nbOfFriends

	updatePoints: (req, status, authorId, adding, done) ->
		id = authorId

		if status

			pointsValue = status.pointsValue || 0

			User.findById id, (err, user) =>
				if err
					done err
				else if user
					if user.points or user.points is 0
						newPoints = user.points + pointsValue * if adding
							1
						else
							-1

						if newPoints < 0
							newPoints = 0

						if equals req.user.id, id
							req.user.points = newPoints
							req.session.user.points = newPoints
						User.updateById id,
							points: newPoints
						, done
					else
						@initPoints req, user, done
		else

			done new Error "status must not be undefined"

	initPoints: (req, user, done) ->
		newPoints = 0
		id = user.id
		Status.find
			author: id
		, (err, statusList) ->
			if err
				done err
			else
				for status in statusList
					medias = status.columns ['images', 'videos', 'links']

					newPoints += StatusPackage.calculatePoints medias, if statusList.length is 1
						# The status just sent is the first one for that user
						# So there no need to init the points
						req.user.numberOfFriends
					else
						# We calculate with 1 friend
						1

				req.user.points = newPoints
				req.session.user.points = newPoints
				User.updateById id,
					points: newPoints
				, done

	checkRightToSee: (req, status) ->
		me = req.user.id
		myFriendsId = req.user.friends.map (friend) ->
			friend._id
		(equals(status.author, me) or equals(status.at, me) or (myFriendsId.contains(status.author, equals) && (status.at is null or myFriendsId.contains(status.at, equals))) or myFriendsId.contains status.at, equals)

	DEFAULT_STATUS_ID: "100000000000000000000001"

	defaultStatus: ->
		title = s("Vos premiers pas")
		_id: @DEFAULT_STATUS_ID
		at: null
		author:
			hashedId: null
			thumb50: '/img/wornet-thumb50.png'
			thumb90: '/img/wornet-thumb90.png'
			thumb200: '/img/wornet-thumb200.png'
			name:
				first: title
				last: ''
				full: title
			fullName: title
			present: false
			points: 0
		concernMe: false
		content: s("Les premiers statuts sont important... Qu'allez-vous poster ?  Un texte bien sympa du type \"Bonjour Wornet !\" ? Vos photos de vacances pour faire rêver vos premiers amis worners ? L'une des vidéos YouTube de la sitcom Warren Flamel inspiré de l'univers d'Harry Potter ?")
		date: new Date()
		status: 'active'
		images: []
		videos: [
			href: '//www.youtube.com/embed/5PC7v6jLQ_s'
			_id: "100000000000000000000002"
		]
		links: []
		pointsValue: 0
		nbLike: 0


module.exports = StatusPackage
