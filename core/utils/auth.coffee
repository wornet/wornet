###
Module that will handle our authentication tasks
###
"use strict"

model 'User'
LocalStrategy = require("passport-local").Strategy
exports.config = (settings) ->


###
A helper method to retrieve a user from a local DB and ensure that the provided password matches.
@param req
@param res
@param next
###
exports.localStrategy = ->
	new LocalStrategy((email, password, done) ->
		
		#Retrieve the user from the database by login
		User.findOne
			email: email
		, (err, user) ->
			
			#If something weird happens, abort.
			return done(err)	if err
			
			#If we couldn't find a matching user, flash a message explaining what happened
			unless user
				return done(null, false,
					message: "Login not found"
				)
			
			#Make sure that the provided password matches what's in the DB.
			unless user.passwordMatches(password)
				return done(null, false,
					message: "Incorrect Password"
				)
			
			#If everything passes, return the retrieved user object.
			done null, user
			return

		return
	)


###
A helper method to determine if a user has been authenticated, and if they have the right role.
If the user is not known, redirect to the login page. If the role doesn't match, show a 403 page.
@param role The role that a user should have to pass authentication.
###
exports.isAuthenticated = ->
	(req, res, next) ->
		
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
			req.flash "error", "Please log in to view this page"
			res.redirect "/user/login"
		
		#Check blacklist for this user's role
		else if blacklist[role] and blacklist[role][route] is true
			model = url: route
			
			#pop the user into the response
			res.locals.user = req.user
			res.unautorized model
		else
			next()
		return


###
A helper method to add the user to the response context so we don't have to manually do it.
@param req
@param res
@param next
###
exports.injectUser = ->
	injectUser = (req, res, next) ->
		res.locals.user = req.user	if req.isAuthenticated()
		next()
		return