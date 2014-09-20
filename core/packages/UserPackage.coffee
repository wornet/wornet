UserPackage =

	askForFriend: (id, req, done) ->
		if empty req.body.userId
			done err: s("Utilisateur introuvable")
		else
			req.user.aksForFriend id, (data) ->
				if empty data.err
					req.user.friendAsks[data.friend.id] = _id: id
					req.getFriends (err, friends, friendAsks) ->
						unless err
							req.user.numberOfFriends = friends.length
							req.user.friends = friends
							req.user.friendAsks = friendAsks
				done data

	renderProfile: (req, res, id = null) ->
		if id is null
			id = req.user._id
		isMe = (req.user?) and (id is req.user._id)
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
								console.warn a[0] + " n'est pas de type Date"
							unless b[0] instanceof Date
								console.warn b[0] + " n'est pas de type Date"
							if a[0] < b[0]
								-1
							else if a[0] > b[0]
								1
							else
								0
						if isMe or !req.user? or empty(req.user.friendAsks)
							askedForFriend = false
						else
							askedForFriend = !empty(req.user.friendAsks[profile._id])
						res.render 'user/profile',
							isMe: isMe
							askedForFriend: askedForFriend
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