'use strict'

StatusPackage =

	getRecentStatusForRequest: (req, res, id = null, data = {}) ->
		onProfile = id or req.data.at
		@getRecentStatus req, res, id, data, onProfile

	getRecentStatus: (req, res, id = null, data = {}, onProfile = false) ->
		next = _next = ->
			if data.recentStatus and data.chat
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
					.select '_id date author at content status images videos links album albumName'
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

	add: (req, done) ->
		if req.data.status
			try
				medias = req.data.medias || {}
				at = req.data.at || null
				unless at is null
					at = cesarRight at
				Status.create
					author: req.user._id
					at: at
					content: req.data.status.content || ""
					images: medias.images || []
					videos: medias.videos || []
					links: medias.links || []
				, (err, originalStatus) ->
					unless err
						status = originalStatus.toObject()
						status.author = req.user.publicInformations()
						next = (usersToNotify) ->
							place = status.at || status.author
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
							req.getFriends (err, friends, friendAsks) ->
								next friends.column '_id'
						else
							req.getUserById at, (err, user) ->
								status.at = if user
									user.publicInformations()
								else
									null
								next [at]
					done err, status, originalStatus
			catch err
				done err
		else
			done new PublicError s("Ce statut est vide")

	put: (req, res, done) ->
		@add req, (err, status, originalStatus) ->
			if err
				res.serverError err
			else
				# if status.at
				# 	NoticePackage.notify [status.at], null,
				# 		action: 'notice'
				# 		notice: [s("{name} a publié un statut sur votre profil.", name: req.user.fullName)]
				albums = []
				count = status.images.length
				if count
					status.images.each ->
						photoId = PhotoPackage.urlToId @src
						PhotoPackage.publish req, photoId, (err, photo) ->
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
												@refreshPreview true, ->
													unless --count
														done status
										else
											done status
								else
									done status
				else
					done status

module.exports = StatusPackage
