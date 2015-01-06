'use strict'

StatusPackage =

	getRecentStatusForRequest: (req, res, id = null, data = {}) ->
		onProfile = id or req.data.at
		@getRecentStatus req, res, id, data, onProfile

	getRecentStatus: (req, res, id = null, data = {}, onProfile = false) ->
		req.getFriends (err, friends, friendAsks) ->
			id = req.getRequestedUserId id
			me = req.user.id
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
									unless missingIds.contains val
										missingIds.push val
								recentStatus.each ->
									if @at
										add @at
									add @author
									true
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
											status.concernMe = [@at, @author].contains me, equals
											status.status = @status
											if @status is 'blocked'
												status.content = ''
											recentStatusPublicData.push status
											true
										data.recentStatus = recentStatusPublicData
										res.json data
								req.getUsersByIds missingIds, done #, searchInDataBase
							else
								data.recentStatus = recentStatusPublicData
								res.json data
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
							NoticePackage.notify usersToNotify, null,
								action: 'status'
								status: status
						if status.at is null
							req.getFriends (err, friends, friendAsks) ->
								next friends.column '_id'
						else
							next [status.at]
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
				if status.at
					NoticePackage.notify [status.at], null,
						action: 'notice'
						notice: [s("{name} a publié un statut sur votre profil.", name: req.user.fullName)]
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
												true
										else
											done status
								else
									done status
						true
				else
					done status

module.exports = StatusPackage
