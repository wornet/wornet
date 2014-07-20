###
Module that will handle our authentication tasks
###
"use strict"

model 'User'

# Set the remember cookie to recognize the users who checked the remember option
exports.remember = (res, id) ->
	res.cookie 'remember', id,
		maxAge: 6 * 30 * 24 * 60 * 60
		httpOnly: true

# Get user id remembered with cookie
exports.remembered = (req, done) ->
	id = req.cookie 'remember'
	if id
		User.findOne
			_id: id
		, (err, user) ->
			if err
				done false, err
			else
				done user
	else
		done false

# Delete user session and cookie
exports.logout = (req, res) ->
	delete res.locals.user
	delete req.user
	delete req.session.user
	if req.cookie 'remember'
		res.clearCookie 'remember'

# Store user in session, and append to the request object
exports.auth = (req, res, user) ->
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
		res.locals.user = req.session.user
		req.user = req.session.user
		next()
	else
		exports.remembered req, (user, err) ->
			if user
				exports.auth req, res, user
			next()

###
A helper method to determine if a user has been authenticated, and if they have the right role.
If the user is not known, redirect to the login page. If the role doesn't match, show a 403 page.
@param role The role that a user should have to pass authentication.
###
exports.isAuthenticated = (req, res, next) ->
	exports.tryLogin req, res, ->

		# Access map
		auth =
			"/": true
			"/admin": true
			"/profile": true
			"/agenda": true
			"/user/profile": true

		blacklist = user:
			"/admin": true

		route = req.url
		# Get user role (in any user connected : empty string)
		role = (if (req.user and req.user.role) then req.user.role else "")
		# If the URL is in the access restricted list
		if auth[route]
			# If any user are connected
			unless req.user
				# If the user is not authorized, save the location that was being accessed so we can redirect afterwards.
				req.session.goingTo = req.url
				if ['/', '/user/profile', '/profile'].indexOf(route) is -1
					req.flash "loginErrors", s("Connectez-vous pour accéder à cette page.")
				res.redirect "/user/login"

			# Check blacklist for this user's role
			else if blacklist[role] and blacklist[role][route] is true
				model = url: route
				# Pop the user into the response
				res.locals.user = req.user
				res.unautorized model
			else
				next()
		else
			next()
