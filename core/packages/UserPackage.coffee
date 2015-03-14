'use strict'

randomUsers = []
randomUsersLastRetreive = 0

UserPackage =

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
			else if typeof arg is 'number'
				limit = arg
			else if typeof arg is 'function'
				done = arg
			else
				query = strval arg
		exclude ||= []
		done ||= ->
		query ||= "-"
		limit ||= 8
		letters =
			a: 'âàäãÂÀÄÃ'
			e: 'éèêëÉÈÊË'
			c: 'çÇ'
			i: 'îïìÎÏÌ'
			u: 'ùûüÙÛÜ'
		query = query.toLowerCase()
		for letter, list of letters
			list = '[' + letter + list + ']'
			query = query.replace (new RegExp list, 'gi'), list
		pattern = '(' + query.replace(/\s+/g, '|') + ')'
		regexp = new RegExp pattern, 'gi'
		User.find
			'name.first': regexp
			'name.last': regexp
			id: $nin: exclude
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
					id: $nin: exclude
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
					req.user.aksForFriend id, (data) ->
						next = ->
							done data
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
		@refreshFriends req, (err) ->
			if err
				done err: err
			else
				Friend.findOneAndUpdate { _id: id, askedTo: req.user._id }, { status: status }, {}, (err, friend) ->
					if ! err and friend and typeof req.body? and req.body.id?
						end = ->
							req.cacheFlush 'friends'
							Friend.count
								$or: [
									askedTo: req.user._id
								,
									askedFrom: req.user._id
								]
								status: 'accepted'
							, (err, count) ->
								unless err
									req.user.numberOfFriends = count
									req.user.save()
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
						delete req.user.friendAsks[id]
						delete req.session.user.friendAsks[id]
						delete req.session.friendAsks[id]
						if status is 'accepted'
							User.findById friend.askedFrom, (err, user) ->
								if user and !err
									req.addFriend user
									dataWithUser = username: jd 'span.username ' + req.user.fullName
									img = jd 'img(src="' + escape(req.user.thumb50) + '" alt="' + escape(req.user.fullName) + '" data-id="' + req.user.hashedId + '" data-toggle="tooltip" data-placement="top" title="' + escape(req.user.fullName) + '").thumb'
									NoticePackage.notify [friend.askedFrom], null,
										action: 'friendAccepted'
										deleteFriendAsk: id
										addFriend: req.user
										user: req.user.publicInformations()
										notification: img + " " + s("{username} fait maintenant partie de vos amis.", dataWithUser)
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
		isMe = (req.user?) and (id is req.user.id)
		@randomUsers (users) ->
			users = users.filter (user) ->
				user._id isnt req.user._id
			done = (profile) ->
				profile = objectToUser profile
				profile.getFriends (err, friends, friendAsks) ->
					if err
						res.serverError err
					else
						friendsThumb = friends.pickUnique config.wornet.limits.friendsOnProfile
						try
							if isMe or !req.user? or empty req.user.friendAsks
								askedForFriend = false
							else
								askedForFriend = req.user.friendAsks.has hashedId: cesarLeft profile.id
							if isMe or !req.user? or empty friends
								isAFriend = false
							else
								isAFriend = friends.has id: req.user.id
						catch err
							warn err
						res.render template,
							isMe: isMe
							askedForFriend: askedForFriend
							isAFriend: isAFriend
							profile: profile
							profileAlerts: req.getAlerts 'profile'
							numberOfFriends: friends.length
							friends: if isMe then friendsThumb else []
							friendAsks: if isMe then friendAsks else {}
							userTexts: userTexts()
							users: users
			if isMe
				done req.user
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
