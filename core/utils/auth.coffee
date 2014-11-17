###
Module that will handle our authentication tasks
###
"use strict"

model 'User'

# Set the remember cookie to recognize the users who checked the remember option
exports.remember = (res, id) ->
	res.cookie config.wornet.remember.key, id,
		maxAge: config.wornet.remember.ttl.days
		httpOnly: true

# Get user id remembered with cookie
exports.remembered = (req, done) ->
	id = req.cookie config.wornet.remember.key
	if id and id isnt config.wornet.remember.off
		User.findOne
			_id: id
		, (err, user) ->
			if err
				done false, err
			else
				done user, null, id
	else
		done false

# Know if the visitor if a new visitor
exports.isNewVisitor = (req) ->
	empty req.cookie config.wornet.remember.key

# Know if the visitor if a new visitor
exports.isReturningVisitor = (req) ->
	!exports.isNewVisitor(req)

# Delete user session and cookie
exports.logout = (req, res) ->
	delete res.locals.user
	delete req.user
	delete req.session.user
	req.cacheFlush()
	exports.remember res, config.wornet.remember.off

# Store user in session, and append to the request object
exports.auth = (req, res, user) ->
	user = objectToUser user
	res.locals.user = user
	req.user = user
	req.session.user = user

exports.login = (req, res, done) ->
	#Retrieve the user from the database by login
	User.findOne
		email: req.body.email
	, (err, user) ->

		# If something weird happens, abort.
		if err
			req.flash "loginErrors", err unless req.xhr
			return done err

		incorrectLoginMessage = s("Veuillez vérifier votre e-mail et votre mot de passe.")
		# If we couldn't find a matching user, flash a message explaining what happened
		unless user
			req.flash "loginErrors", incorrectLoginMessage unless req.xhr
			return done incorrectLoginMessage, false

		# Make sure that the provided password matches what's in the DB.
		unless user.passwordMatches req.body.password
			req.flash "loginErrors", incorrectLoginMessage unless req.xhr
			return done incorrectLoginMessage, false

		# If user ask for remember him
		if req.body.remember
			exports.remember res, user._id

		# If everything passes, return the retrieved user object.
		exports.auth req, res, user
		done null, user


# Try to login with session data or remember cookie
exports.tryLogin = (req, res, next) ->
	if req.session.user?
		exports.auth req, res, req.session.user
		next()
	else
		exports.remembered req, (user, err, id) ->
			if user
				exports.auth req, res, user
				exports.remember res, id
			else
				if exports.isNewVisitor req
					res.locals.isNewVisitor = true
				exports.remember res, config.wornet.remember.off
			next()

###
Return true if a value is in a list (after solving jokers)
@return boolean match
###
exports.inList = (value, list) ->
	for match in list
		match = new RegExp match.replace(/\*\*/g, '.*').replace(/\*/g, '[^/]*')
		if match.test value
			return true
	false

###
A helper method to determine if a user has been authenticated, and if they have the right role.
If the user is not known, redirect to the login page. If the role doesn't match, show a 403 page.
@param role The role that a user should have to pass authentication.
###
exports.isAuthenticated = (req, res, next) ->
	if req.isStatic?
		next()
	else
		exports.tryLogin req, res, ->

			done = ->
				# Access map
				auth = [
					"/admin"
					"/agenda"
					"/photos"
					"/friend/**"
					"/user/notify"
					"/user/profile/**"
					"/user/status/**"
				]

				blacklist = user: [
					"/admin"
				]

				res.locals.noIndex = false
				route = req.url
				# Get user role (in any user connected : empty string)
				role = (if (req.user and req.user.role) then req.user.role else "")
				# If the URL is in the access restricted list
				if exports.inList route, auth
					# If any user are connected
					unless req.user
						# If the user is not authorized, save the location that was being accessed so we can redirect afterwards.
						isARouteWithoutMessage = (route is '/')
						if req.isJSON
							if isARouteWithoutMessage
								data.err = s("Connectez-vous pour accéder à cette page.")
							data = goingTo: req.url
							res.json data
						else
							req.goingTo req.url
							if isARouteWithoutMessage
								req.flash "loginErrors", s("Connectez-vous pour accéder à cette page.")
							res.redirect "/"

					# Check blacklist for this user's role
					else if blacklist[role] and exports.inList route, blacklist[role]
						model = url: route
						res.unautorized model
					else
						res.locals.noIndex = true
						next()
				else
					next()

			if req.user
				req.getFriends (err, friends, friendAsks) ->
					req.user.friendAsks = friendAsks
					req.user.friends = friends
					req.user.numberOfFriends = friends.length
					req.session.user.friendAsks = friendAsks
					req.session.user.friends = friends
					req.session.user.numberOfFriends = friends.length
					if err
						res.serverError err
					else
						req.user.notifications = []
						for id, friend of friendAsks
							if friend.askedTo
								req.user.notifications.push [Date.fromId(id), friend, id]
						done()
			else
				done()
