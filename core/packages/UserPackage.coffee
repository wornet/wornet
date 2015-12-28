'use strict'

randomUsers = []
randomPublicUsers = []
randomPublicUsersLastRetreive = 0
randomUsersLastRetreive = 0
friendsCoupleCacheLifeTime = 1.hour

UserPackage =

	DEFAULT_SEARCH_LIMIT: 8

	hiddenSuggests: {}

	getIDCouple: (a, b) ->
		a = strval a.id || a
		b = strval b.id || b
		ids = [a, b]
		ids.sort()
		ids.join '-'

	areFriends: (a, b, areFriends, done) ->
		key = @getIDCouple a, b
		cache 'friends-' + key, areFriends, done

	cacheFriends: (a, b, areFriends = true) ->
		key = @getIDCouple a, b
		areFriends = if areFriends
			1
		else
			0
		memSet 'friends-' + key, areFriends

	getAlbums: (userIds, done) ->
		if 'function' is typeof limit
			done = limit
			limit = 0
		Album.find
			user: $in: userIds
		.sort lastAdd: 'desc'
		.exec (err, albums) ->
			if err
				done err
			else
				result = {}
				albumIds = []
				tabAlbum = {}
				for id in userIds
					result[id] = []
				for album in albums
					result[album.user].push album
				done null, result

	isMeOrAFriend: (req, hashedId) ->
		if req.user
			if req.user.hashedId is hashedId
				true
			else
				friendsHashedIds = req.user.friends.map (friend) ->
					friend.hashedId
				friendsHashedIds.contains hashedId
		else
			false

	getAlbumsForMedias: (req, hashedId, all = false,  done) ->
		isAPublicAccount req, hashedId, true, (publicAccount) =>
			if @isMeOrAFriend(req, hashedId) or publicAccount
				idUser = cesarRight hashedId
				UserAlbums.findOne
					user: idUser
				, (err, userAlbums) ->
					if err
						warn err
					else if !userAlbums or (userAlbums and (!userAlbums.lastFour or !userAlbums.lastFour.length))
						done null, {}, 0
					else
						theLastFour = userAlbums.lastFour

						Album.find
							user: idUser
						.sort lastAdd: 'desc'
						.exec (err, allAlbums) ->
							albumIdsList = allAlbums.column '_id'
							Photo.aggregate [
								$match:
									status: "published"
									album: $in: albumIdsList
							,
								$group:
									_id: "$album"
									count: $sum: 1
							], (err, allData) ->
								if err
									warn err
								else
									# all non empty albums
									allData = allData.filter (data) ->
										data.count isnt 0
									nbAlbumsNotEmpty = allData.length

									tabAlbum = {}
									photoIds = []
									if !all
										albums = allAlbums.filter (album) ->
											theLastFour.contains album._id
										# to keep the order
										for id in theLastFour
											for album in albums
												if strval(id) is strval(album._id)
													for data in allData
														if equals data._id, album._id
															albumObj = album.toObject()
															albumObj.preview = []
															albumObj.nbPhotos = data.count
															photoIds = photoIds.concat album.preview
															tabAlbum[album.id] = albumObj
									else
										for album in allAlbums
											for data in allData
												if equals data._id, album._id
													albumObj = album.toObject()
													albumObj.preview = []
													albumObj.nbPhotos = data.count
													photoIds = photoIds.concat album.preview
													tabAlbum[album.id] = albumObj

									Photo.find
										_id: $in: photoIds
										status: "published"
									, (err, photos) ->
										if err
											warn err
										else
											for photo in photos
												photoPath = photo.photo
												photo = photo.toObject()
												photo.src = photoPath
												tabAlbum[photo.album].preview.push photo
											done null, tabAlbum, nbAlbumsNotEmpty
			else
				done new PublicError s('Vous ne pouvez pas voir ces médias.')


	search: ->
		for arg in arguments
			if arg instanceof mongoose.Types.ObjectId
				exclude = [arg]
			else if arg instanceof Array
				exclude = arg
			else if arg instanceof RegExp
				regexp = arg
			else if typeof arg is 'number'
				limit = arg
			else if typeof arg is 'function'
				done = arg
			else
				query = strval arg
		exclude ||= []
		done ||= ->
		query ||= "-"
		limit ||= @DEFAULT_SEARCH_LIMIT
		regexp ||= query.toBeginRegExp true
		User.find
			'name.first': regexp
			'name.last': regexp
			_id: $nin: exclude
		.limit limit
		.exec (err, users) ->
			remind = limit - users.length
			if err or remind <= 0
				done err, users
			else if users
				each users, (user) ->
					exclude.push user.id
				User.find
					$or: [
						'name.first': regexp
					,
						'name.last': regexp
					]
					_id: $nin: exclude
				.limit remind
				.exec (err, moreUsers) ->
					if moreUsers and moreUsers.length
						for user in moreUsers
							users.push user
					done err, users

		###
		User.find
				$text: $search: query
			,
				score: $meta: 'textScore'
			.sort score: $meta: 'textScore'
			.limit limit
			.exec (err, users) ->
				if err
					done err
				else
					if users and users.length > 0
						done null, users
					else
						regexp = new RegExp query, 'gi'
						User.find $or: [
								'name.first': regexp
							,
								'name.last': regexp
							]
							.limit limit
							.exec done
		###

	refreshFriends: (req, done) ->
		req.getFriends (err, friends, friendAsks) ->
			unless err
				req.user.numberOfFriends = friends.length
				req.user.friends = friends
				req.user.friendAsks = friendAsks
				req.session.user.friends = friends
				req.session.user.friendAsks = friendAsks
				req.session.friends = friends
				req.session.friendAsks = friendAsks
				done err

	refreshFollows: (req, done) ->
		Follow.find
			$or: [
				follower: req.user.id
			,
				followed: req.user.id
			]
		, (err, allFollows) ->
			unless err
				iFollow = []
				iamFollowed = []
				for follow in allFollows
					if equals follow.follower, req.user.id
						iFollow.push follow.followed
					else
						iamFollowed.push follow.follower
				req.user.follower = iamFollowed
				req.user.following = iFollow
				req.session.follower = iamFollowed
				req.session.following = iFollow
			done err

	askForFriend: (id, req, done) ->
		if empty id
			done err: s("Utilisateur introuvable")
		else
			@refreshFriends req, (err) ->
				if err
					done err: err
				else
					id = cesarRight id
					req.user.askForFriend id, (data) ->
						next = ->
							done data
							unless data.err or equals req.user.id, data.friend.askedTo
								dataWithUser = username: jd 'span.username ' + req.user.fullName
								NoticePackage.notify [data.friend.askedTo], null,
									action: 'askForFriend'
									askForFriend: req.user
									user: req.user.publicInformations()
									id: data.friend.id
						if empty data.err
							User.findById id, (err, user) ->
								if err
									data.err = err
								if user
									req.session.reload (err) ->
										if err
											throw err
										req.cacheFlush 'friends'
										req.user.friendAsks[data.friend.id] = user
										req.session.user.friendAsks = req.user.friendAsks
										req.session.friendAsks = req.user.friendAsks
										req.session.save (err) ->
											if err
												throw err
								next()
						else
							next()

	setFriendStatus: (req, id, status, done) ->
		id = strval id
		me = req.user
		self = @
		@refreshFriends req, (err) ->
			if err
				done err: err
			else
				where =
					_id: id
					askedTo: me._id
					status: $ne: status
				set = status: status
				Friend.findOneAndUpdate where, set, {}, (err, friend) ->
					if ! err and friend and id
						end = ->
							req.cacheFlush 'friends'
							Friend.count
								$or: [
									askedTo: me._id
								,
									askedFrom: me._id
								]
								status: 'accepted'
							, (err, count) ->
								unless err
									me.numberOfFriends = count
									me.save()
							Friend.count
								$or: [
									askedTo: friend.askedFrom
								,
									askedFrom: friend.askedFrom
								]
								status: 'accepted'
							, (err, count) ->
								unless err
									friend.numberOfFriends = count
									friend.save()
						delete me.friendAsks[id]
						delete req.session.user.friendAsks[id]
						delete req.session.friendAsks[id]
						if status is 'accepted'
							self.cacheFriends me, friend.askedFrom, true
							User.findById friend.askedFrom, (err, user) ->
								if user and !err
									sendNotice = (user, userId, notice) ->
										NoticePackage.notify [userId], null,
											action: 'friendAccepted'
											deleteFriendAsk: id
											addFriend: user
											user: user.publicInformations()
											notification: notice
											notice: [notice, 'friendAccepted', me, null, user]
									req.addFriend user
									dataWithUser = username: jd 'span.username ' + me.fullName
									img = jd 'img(src="' + escape(me.thumb50) + '" alt="' + escape(me.fullName) + '" data-id="' + me.hashedId + '" data-toggle="tooltip" data-placement="top" title="' + escape(me.fullName) + '").thumb'
									sendNotice me, friend.askedFrom, '<span data-href="/' + me.uniqueURLID + '">' +
										img + " " + s("{username} a accepté votre demande !", dataWithUser) +
										'</span>'
									dataWithUser = username: jd 'span.username ' + user.fullName
									img = jd 'img(src="' + escape(user.thumb50) + '" alt="' + escape(user.fullName) + '" data-id="' + user.hashedId + '" data-toggle="tooltip" data-placement="top" title="' + escape(user.fullName) + '").thumb'
									sendNotice user, friend.askedTo, '<span data-href="/' + user.uniqueURLID + '">' +
										img + " " + s("Vous êtes dorénavant ami avec {username} !", dataWithUser) +
										'</span>'
									end()
						else if status isnt 'waiting'
							NoticePackage.notify [friend.askedFrom], null,
								deleteFriendAsk: id
							end()
					done
						err: err
						friend: friend

	renderHome: (req, res, id = null, template = 'index') ->
		@renderProfile req, res, id, template

	randomUsers: (done) ->
		done randomUsers
		now = time()
		if now - randomUsersLastRetreive > 30.seconds
			randomUsersLastRetreive = now
			where = photoId: $ne: null
			limit = limit: config.wornet.limits.theyUseWornet
			User.findRandom where, {}, limit, (err, users) ->
				if users and users.length
					randomUsers = users

	randomPublicUsers: (myId, forceReload, done) ->
		if "function" is typeof forceReload
			done = forceReload
			forceReload = false
		done randomPublicUsers
		now = time()
		if ( now - randomPublicUsersLastRetreive > 30.seconds ) or forceReload
			randomPublicUsersLastRetreive = now
			configLimit = config.wornet.limits.publicSuggestions + 1
			limit = limit: configLimit
			Follow.find
				follower: myId
			, (err, follow) ->
				warn err if err
				followed = if follow
					follow.column('followed')
				else
					[]
				followed.push myId
				exceptions = if UserPackage.hiddenSuggests[myId]
					followed.merge(UserPackage.hiddenSuggests[myId]).unique().map strval
				else
					followed.map strval
				where =
					photoId: $ne: null
					accountConfidentiality: "public"
					certifiedAccount: true
					_id: $nin: exceptions
				User.findRandom where, {}, limit, (err, certifiedUsers) ->
					warn err if err
					if certifiedUsers and certifiedUsers.length
						randomPublicUsers = certifiedUsers.map (user) ->
							user.publicInformations()
					else
						randomPublicUsers = []
						certifiedUsers = []
					if certifiedUsers.length < configLimit
						where =
							photoId: $ne: null
							accountConfidentiality: "public"
							$or: [
								certifiedAccount: $exists: false
							,
								certifiedAccount: null
							,
								certifiedAccount: false
							]
							_id: $nin: exceptions
						limit = limit: ( configLimit - certifiedUsers.length )
						User.findRandom where, {}, limit, (err, users) ->
							if users and users.length
								randomPublicUsers.merge users.map (user) ->
									user.publicInformations()
								.unique()
							else
								if !certifiedUsers or !certifiedUsers.length
									randomPublicUsers = []

	findNextRandomPublic: (req, alreadyPresent, done) ->
		myId = req.user._id
		Follow.find
			follower: req.user._id
			followed: $ne: cesarRight req.data.hashedId
		, (err, follow) ->
			warn err if err
			followed = if follow
				follow.column('followed')
			else
				[]
			followed.push myId
			exceptions = if UserPackage.hiddenSuggests[myId]
				followed.merge(alreadyPresent).merge(UserPackage.hiddenSuggests[myId]).unique().map strval
			else
				followed.merge(alreadyPresent).unique().map strval
			where =
				photoId: $ne: null
				accountConfidentiality: "public"
				certifiedAccount: true
				_id: $nin: exceptions
			User.findOne where, (err, certifiedUser) ->
				warn err if err
				if certifiedUser
					done certifiedUser.publicInformations()
				else
					where =
						photoId: $ne: null
						accountConfidentiality: "public"
						$or: [
							certifiedAccount: $exists: false
						,
							certifiedAccount: null
						,
							certifiedAccount: false
						]
						_id: $nin: exceptions
					User.findOne where, (err, user) ->
						warn err if err
						if user
							done user.publicInformations()
						else
							done null

	renderProfile: (req, res, id = null, template = 'user/profile') ->
		id = req.getRequestedUserId id
		me = req.user || req.session.user
		isAPublicAccount = false
		if !me
			isMe = false
		else
			isMe = me and equals id, me.id
		self = @
		@randomUsers (users) =>
			users = users.filter (user) ->
				if me
					! equals user._id, me._id
				else
					true
			@randomPublicUsers me.id, (publicUsers) ->
				publicUsers = publicUsers.filter (user) ->
					if me
						! equals user.hashedId, me.hashedId
					else
						true

				done = (profile, isAFriend, nbFollowers = 0, amIAFollower = false, nbFollowing = 0) ->
					profile = objectToUser profile
					isAPublicAccount = profile.accountConfidentiality is "public"
					profile.getFriends (err, friends, friendAsks) ->
						if err
							res.serverError err
						else
							friendsThumb = friends.copy().pickUnique config.wornet.limits.friendsOnProfile
							end = (isAFriend) ->
								myfriendAskPending = false
								if !isAFriend and !empty friendAsks
									for id, friendAsk of friendAsks
										if req.user && friendAsk.hashedId is req.user.hashedId
											myfriendAskPending = true
								res.render template,
									isMe: isMe
									askedForFriend: askedForFriend
									isAFriend: !! isAFriend
									isABestFriend: me && me.isABestFriend profile.hashedId
									isAPublicAccount: isAPublicAccount
									profile: profile
									profileAlerts: req.getAlerts 'profile'
									numberOfFriends: friends.length
									numberOfFollowers: nbFollowers
									amIAFollower: !! amIAFollower
									numberOfFollowing: nbFollowing
									friends: if isMe || !! isAFriend || isAPublicAccount then friendsThumb else []
									friendAsks: if isMe then friendAsks else {}
									myfriendAskPending: myfriendAskPending
									userTexts: userTexts()
									users: users
									publicUsers: publicUsers
							if isAFriend is null
								try
									askedForFriend = if isMe or (! me) or empty me.friendAsks
										false
									else
										me.friendAsks.has hashedId: cesarLeft profile.id
									if isMe or (! me) or empty friends
										end false
									else
										self.areFriends me, profile, ->
											friends.has id: me.id
										, end
								catch err
									warn err
									end false
							else
								end isAFriend
				if isMe
					done me, false
				else
					User.findById id, (err, user) ->
						if err
							res.notFound()
						else
							isAPublicAccount = user.accountConfidentiality is "public"
							if isAPublicAccount and !req.user
								done user, false
							else
								req.getFriends (err, friends, friendAsks) ->
									isAFriend = if friends and friends.getLength() > 0
										friends.has id: id
									else
										null

									if isAPublicAccount
										Follow.count
											followed: id
										, (err, nbFollowers) ->
											warn err if err
											Follow.count
												followed: id
												follower: me
											, (err, amIAFollower) ->
												warn err if err
												Follow.count
													follower: id
												, (err, nbFollowing)->
													warn err if err
													done user, isAFriend, nbFollowers, amIAFollower, nbFollowing

									else
										done user, isAFriend

	getUserModificationsFromRequest: (req) ->
		userModifications = {}
		for key, val of req.body
			if empty val
				val = null
			switch key
				when 'birthDate'
					birthDate = inputDate val
					if birthDate.isValid()
						userModifications.birthDate = birthDate
				when 'maskBirthDate', 'maskFriendList', 'allowFriendPostOnMe', 'maskFollowList'
					userModifications[key] = val is 'on'
				when 'name.first'
					unless userModifications.name
						userModifications.name = req.user.name
					userModifications.name.first = val
				when 'name.last'
					unless userModifications.name
						userModifications.name = req.user.name
					userModifications.name.last = val
				when 'photoId'
					if PhotoPackage.allowedToSee req, val
						userModifications.photoId = val
				when 'maritalStatus', 'loveInterest', 'accountConfidentiality'
					unless User.schema.path(key).enumValues.contains val
						val = null
					userModifications[key] = val
				when 'email', 'password'
					if val?
						userModifications[key] = val
				when 'city', 'birthCity', 'job', 'jobPlace', 'biography', 'sex'
					userModifications[key] = val
		userModifications

	setAsProfilePhoto: (req, res, photo, done) ->
		if photo
			Photo.findOneAndUpdate
				_id: photo._id
			,
				status: "published"
			, (err, photoBase) ->
				if err
					warn err
				else
					updateUser req, photoId: photo._id, ->
						Album.findOne
							_id: photoBase.album
						, (err, album) ->
							if !err and album
								UserAlbums.touchAlbum req.user, album._id, (err, result) ->
									if err
										warn err
								album.refreshPreview done

		else
			warn new Error s("Aucune ou plusieurs Photos envoyées à setAsProfilePhoto")

module.exports = UserPackage
