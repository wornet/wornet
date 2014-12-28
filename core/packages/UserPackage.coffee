'use strict'

UserPackage =

	search: ->
		for arg in arguments
			if arg instanceof ObjectId
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
		regexp = new RegExp query, 'gi'
		User.find
			$or: [
				'name.first': regexp
			,
				'name.last': regexp
			]
			id: $not: $in: exclude
		.limit limit
		.exec done

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
				done err

	askForFriend: (id, req, done) ->
		if empty req.body.userId
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
								user: req.user.publicInformations()
								id: data.friend.id
						if empty data.err
							User.findById id, (err, user) ->
								if err
									data.err = err
								if user
									req.user.friendAsks[data.friend.id] = user
									req.session.user.friendAsks = req.user.friendAsks
								next()
						else
							next()

	setFriendStatus: (req, status, done) ->
		isRequest = typeof req is 'object' and req.body? and req.body.id?
		if isRequest
			id = req.body.id
		else
			id = strval req
		@refreshFriends req, (err) ->
			if err
				done err: err
			else
				Friend.findOneAndUpdate { _id: id, askedTo: req.user._id }, { status: status }, {}, (err, friend) ->
					if ! err and friend and isRequest
						delete req.user.friendAsks[id]
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
						else if status isnt 'waiting'
							NoticePackage.notify [friend.askedFrom], null,
								deleteFriendAsk: id
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
					done
						err: err
						friend: friend

	renderHome: (req, res, id = null, template = 'index') ->
		@renderProfile req, res, id, template

	renderProfile: (req, res, id = null, template = 'user/profile') ->
		id = req.getRequestedUserId id
		isMe = (req.user?) and (id is req.user.id)
		cache 'users', 60, (done) ->
			User.find(
				if req.user
					_id: $ne: req.user._id
				else
					{}
			, (err, users) ->
				if err
					res.notFound()
				else
					done users
			)
		, (users) ->
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
							friends: friendsThumb
							friendAsks: friendAsks
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
				val = undefined
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
						val = undefined
					userModifications[key] = val
				when 'email', 'password'
					if val?
						userModifications[key] = val
				when 'city', 'birthCity', 'job', 'jobPlace', 'biography'
					userModifications[key] = val
		userModifications

module.exports = UserPackage
