'use strict'

randomUsers = []
randomUsersLastRetreive = 0
friendsCoupleCacheLifeTime = 1.hour

UserPackage =

	DEFAULT_SEARCH_LIMIT: 8

	getIDCouple: (a, b) ->
		a = strval a.id || a
		b = strval b.id || b
		ids = [a, b]
		ids.sort()
		ids.join '-'

	areFriends: (a, b, calculate, done) ->
		key = @getIDCouple a, b
		cache 'friends-' + key, friendsCoupleCacheLifeTime, calculate, done

	cacheFriends: (a, b, areFriends = true) ->
		key = @getIDCouple a, b
		memSet 'friends-' + key, areFriends, friendsCoupleCacheLifeTime

	getAlbums: (userIds, done) ->
		Album.find
			user: $in: userIds
		.sort _id: 'asc'
		.exec (err, albums) ->
			if err
				done err
			else
				result = {}
				for id in userIds
					result[id] = []
				for album in albums
					result[album.user].push album
				done null, result

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
		regexp ||= query.toSearchRegExp()
		User.find
			'name.first': regexp
			'name.last': regexp
			_id: $nin: exclude
		.limit limit
		.exec (err, users) ->
			remind = limit - users.length
			if err or remind <= 0
				done err, users
			else
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
											notice: [notice]
									req.addFriend user
									dataWithUser = username: jd 'span.username ' + me.fullName
									img = jd 'img(src="' + escape(me.thumb50) + '" alt="' + escape(me.fullName) + '" data-id="' + me.hashedId + '" data-toggle="tooltip" data-placement="top" title="' + escape(me.fullName) + '").thumb'
									sendNotice me, friend.askedFrom, '<span data-href="/user/profile/' + me.hashedId + '/' + encodeURIComponent(me.name.full) + '">' +
										img + " " + s("{username} a accepté votre demande !", dataWithUser) +
										'</span>'
									dataWithUser = username: jd 'span.username ' + user.fullName
									img = jd 'img(src="' + escape(user.thumb50) + '" alt="' + escape(user.fullName) + '" data-id="' + user.hashedId + '" data-toggle="tooltip" data-placement="top" title="' + escape(user.fullName) + '").thumb'
									sendNotice user, friend.askedTo, '<span data-href="/user/profile/' + user.hashedId + '/' + encodeURIComponent(user.name.full) + '">' +
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

	renderProfile: (req, res, id = null, template = 'user/profile') ->
		id = req.getRequestedUserId id
		me = req.user || req.session.user
		unless me
			warn "me is not defined"
		isMe = me and equals id, me.id
		self = @
		@randomUsers (users) ->
			users = users.filter (user) ->
				! equals user._id, me._id
			done = (profile) ->
				profile = objectToUser profile
				profile.getFriends (err, friends, friendAsks) ->
					if err
						res.serverError err
					else
						friendsThumb = friends.pickUnique config.wornet.limits.friendsOnProfile
						end = (isAFriend) ->
							res.render template,
								isMe: isMe
								askedForFriend: askedForFriend
								isAFriend: isAFriend
								isABestFriend: me.isABestFriend profile.hashedId
								profile: profile
								profileAlerts: req.getAlerts 'profile'
								numberOfFriends: friends.length
								friends: if isMe then friendsThumb else []
								friendAsks: if isMe then friendAsks else {}
								userTexts: userTexts()
								users: users
						try
							askedForFriend = if isMe or (! me) or empty me.friendAsks
								false
							else
								me.friendAsks.has hashedId: cesarLeft profile.id
							if isMe or (! me) or empty friends
								end false
							else
								self.areFriends me, profile, (done) ->
									done friends.has id: me.id
								, end
						catch err
							warn err
							end false
			if isMe
				done me
			else
				User.findById id, (err, user) ->
					if err
						res.notFound()
					else
						done user

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
				when 'maritalStatus', 'loveInterest'
					unless User.schema.path(key).enumValues.contains val
						val = null
					userModifications[key] = val
				when 'email', 'password'
					if val?
						userModifications[key] = val
				when 'city', 'birthCity', 'job', 'jobPlace', 'biography'
					userModifications[key] = val
		userModifications

module.exports = UserPackage
