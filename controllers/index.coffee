'use strict'

module.exports = (router) ->


	new PagesManager router
		.page '/newsroom'
		.page '/jobs'
		.page '/legals'


	# When login/signin/profile page displays
	router.get '/', (req, res) ->
		if req.user
			cache 'users', 60, (done) ->
				User.find()
					.where('_id').ne req.user._id
					.exec (err, users) ->
						done users
			, (users) ->
				req.getFriends (friends, friendAsks) ->
					notifications = []
					req.user.friends = friends
					req.user.friendAsks = friendAsks
					friendAsks['540d5304943d6f1038c24c8a'] = users[0]
					for id, friend of friendAsks
						notifications.push [Date.fromId(id), friend, id]
					notifications.push [new Date, "Nouveau"]
					notifications.push [(new Date).subMonths(1), date()]
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
					res.render 'user/profile',
						users: users
						notifications: notifications
		else
			# Get errors in flash memory (any if AJAX is used and works on client device)
			res.render 'user/login', loginErrors: req.flash 'loginErrors' # Will be removed when errors will be displayed on the next step


	alias =
		'user/profile': ''
		'user/login': ''
		signin: 'user/signin'
		logout: 'user/logout'
		'forgotten-password': 'user/forgotten-password'
		profile: ''

	for as, route of alias
		((as, route) ->
			router.get '/' + as, (req, res) ->
				res.redirect '/' + route
		)(as, route)
