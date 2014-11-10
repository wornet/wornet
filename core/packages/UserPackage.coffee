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
					req.user.aksForFriend id, (data) ->
						if empty data.err
							req.user.friendAsks[data.friend.id] = _id: id
						done data

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
				Friend.update { _id: id, askedTo: req.user._id }, { $set: status: status }, {}, (err, friend) ->
					if ! err and isRequest
						delete req.user.friendAsks[data.friend.id]
						if status is 'accepted'
							req.user.friends.push _id: friend.askedFrom
					done
						err: err
						friend: friend

	renderHome: (req, res, id = null, template = 'index') ->
		@renderProfile req, res, id, template

	renderProfile: (req, res, id = null, template = 'user/profile') ->
		id = req.getRequestedUserId id
		isMe = (req.user?) and (id is req.user.id)
		cache 'users', 60, (done) ->
			query = User.find()
			if req.user
				query = query.where('_id').ne req.user._id
			query.exec (err, users) ->
					done users
		, (users) ->
			done = (profile) ->
				notifications = []
				profile.getFriends (err, friends, friendAsks) ->
					if err
						res.serverError err
					else
						friendsThumb = friends.pickUnique config.wornet.limits.friendsOnProfile
						notifications.sort (a, b) ->
							unless a[0] instanceof Date
								console['warn'] a[0] + " n'est pas de type Date"
							unless b[0] instanceof Date
								console['warn'] b[0] + " n'est pas de type Date"
							if a[0] < b[0]
								-1
							else if a[0] > b[0]
								1
							else
								0
						try
							if isMe or !req.user? or empty req.user.friendAsks
								askedForFriend = false
							else
								askedForFriend = req.user.friendAsks.has _id: profile._id
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
						done user

module.exports = UserPackage
