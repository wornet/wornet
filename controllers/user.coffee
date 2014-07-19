'use strict'

module.exports = (router) ->

	templateFolder = 'user'
	loginUrl = '/user/login'

	# When login/signin page displays
	router.get '/login', (req, res) ->

		model = {}
		# Get errors in flash memory (any if AJAX is used and works on client device)
		model.loginErrors = req.flash 'loginErrors'
		model.signinErrors = req.flash 'signinErrors' # Will be removed when errors will be displayed on the next step
		res.render templateFolder + '/login', model

	router.get '/login/check', (req, res) ->

		model = {}
		res.render templateFolder + '/login/check', model

	# When user submit his e-mail and password to log in
	router.post '/login', (req, res) ->

		# Log in user
		auth.login req, res, (err, user) ->
			url = '/'
			if user
				if req.session.goingTo?
					url = req.session.goingTo
			else
				url = loginUrl
			# With AJAX, send JSON
			if req.xhr
				if err
					res.json err: err
				else
					# url to be redirected in goingTo key of the JSON object
					res.json goingTo: url
			# Without AJAX, normal redirection even if an error occured
			else
				res.redirect url

	# When user click on a logout link/button
	router.get '/logout', (req, res) ->

		model = {}
		auth.logout req, res
		if req.body.goingTo?
			req.session.goingTo = req.body.goingTo
		res.redirect loginUrl

	# Any sign in page does not yet exists
	router.get '/signin', (req, res) ->

		res.redirect loginUrl

	# When user submit his e-mail and password to sign in
	router.put '/signin', (req, res) ->

		model = {}
		# A full name must contains a space but is not needed at the first step
		if req.body.name? and req.body.name.full.indexOf(' ') is -1
			req.flash 'signinErrors', s("Veuillez entrer vos prénom et nom séparés d'un espace.")
			res.redirect loginUrl
		# Passwords must be identic
		else if req.body.password isnt req.body.passwordCheck
			req.flash 'signinErrors', s("Veuillez entrer des mots de passe identiques.")
			res.redirect loginUrl # Will be removed when errors will be displayed at the second step
		# If no error
		else
			User.create
				name:
					full: if req.body.name? and req.body.name.full? then req.body.name.full else null
				registerDate: new Date
				email: req.body.email
				password: req.body.password
			, (saveErr, user) ->
				if saveErr
					req.flash 'signinErrors', saveErr
					res.redirect loginUrl
				else
					# if "Se souvenir de moi" est coché
					if req.body.remember?
						auth.remember res, user._id
					# Put user in session
					auth.auth req, res, user
					url = '/'
					if user
						if req.session.goingTo?
							url = req.session.goingTo
					else
						url = loginUrl
					res.redirect url
		# res.render templateFolder + '/signin', model

	router.get '/forgotten-password', (req, res) ->

		model = {}
		res.render templateFolder + '/forgotten-password', model

	router.post '/forgotten-password', (req, res) ->

		model = {}
		res.render templateFolder + '/forgotten-password', model

	router.get '/profile', (req, res) ->

		model = {}
		res.render templateFolder + '/profile', model
