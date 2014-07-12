###
Module that will handle our authentication tasks
###
"use strict"

model 'User'

exports.remember = (res, id) ->
	res.cookie 'remember', id,
		maxAge: 6 * 30 * 24 * 60 * 60
		httpOnly: true

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


exports.logout = (req, res) ->
	delete res.locals.user
	delete req.user
	delete req.session.user
	if req.cookie 'remember'
		res.clearCookie 'remember'

exports.auth = (req, res, user) ->
	res.locals.user = user
	req.user = user
	req.session.user = user

exports.login = (req, res, done) ->
	#Retrieve the user from the database by login
	User.findOne
		email: req.body.email
	, (err, user) ->

		#If something weird happens, abort.
		if err
			req.flash "loginErrors", err
			return done err

		#If we couldn't find a matching user, flash a message explaining what happened
		unless user
			req.flash "loginErrors", "Login not found"
			return done "emailNotFound", false

		#Make sure that the provided password matches what's in the DB.
		unless user.passwordMatches req.body.password
			req.flash "loginErrors", "Incorrect Password"
			return done "incorrectPassword", false

		#If everything passes, return the retrieved user object.
		if req.body.remember
			exports.remember res, user._id
		exports.auth req, res, user
		done null, user


exports.tryLogin = (req, res, next) ->
	if req.url is '/user/login' && typeof(req.body.email) isnt 'undefined' && typeof(req.body.pass) isnt 'undefined'
		exports.login req, res, next
	else if req.session.user?
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

		#access map
		auth =
			"/admin": true
			"/profile": true
			"/user/profile": true

		blacklist = user:
			"/admin": true

		route = req.url
		role = (if (req.user and req.user.role) then req.user.role else "")
		unless auth[route]
			next()
			return

		else unless req.isAuthenticated()
			#If the user is not authorized, save the location that was being accessed so we can redirect afterwards.
			req.session.goingTo = req.url
			req.flash "loginErrors", "Please log in to view this page"
			res.redirect "/user/login"
		
		#Check blacklist for this user's role
		else if blacklist[role] and blacklist[role][route] is true
			model = url: route
			
			#pop the user into the response
			res.locals.user = req.user
			res.unautorized model
		next()
