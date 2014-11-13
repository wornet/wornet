'use strict'

UserPackage =

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
						if empty data.err
							req.user.friendAsks[data.friend.id] = _id: id
						done data
						dataWithUser = username: jd 'span.username ' + req.user.fullName
						NoticePackage.notify [data.friend.askedTo], null,
							action: 'askForFriend'
							user: req.user.publicInformations()
							id: data.friend.id

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
				Friend.findOneAndUpdate { _id: id, askedTo: req.user._id }, { $set: status: status }, {}, (err, friend) ->
					if ! err and friend and isRequest
						delete req.user.friendAsks[id]
						if status is 'accepted'
							req.user.friends.push _id: friend.askedFrom
							dataWithUser = username: jd 'span.username ' + req.user.fullName
							NoticePackage.notify [friend.askedFrom], null,
								action: 'friendAccepted'
								user: req.user.publicInformations()
								notification: s("{username} fait maintenant partie de vos amis.", dataWithUser)
						Friend.count
							$or: [
								askedTo: req.user._id
							,
								askedFrom: req.user._id
							]
							status: 'accepted'
						, (err, count) ->
							log [err, count]
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
							if isMe or !req.user? or empty req.user.friends
								isAFriend = false
							else
								isAFriend = req.user.friends.has id: profile.id
						catch err
							console['warn'] err
						res.render template,
							isMe: isMe
							askedForFriend: askedForFriend
							isAFriend: isAFriend
							profile: profile
							numberOfFriends: friends.length
							friends: friendsThumb
							friendAsks: friendAsks
							users: users
			if isMe
				done req.user
			else
				User.findById id, (err, user) ->
					if err
						res.notFound()
					else
						req.getFriends (err) ->
							done user

module.exports = UserPackage
