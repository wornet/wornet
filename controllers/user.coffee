'use strict'

module.exports = (router) ->

	templateFolder = 'user'
	loginUrl = '/user/login'

	router.get '/login', (req, res) ->

		model = {}
		model.loginErrors = req.flash 'loginErrors'
		model.signinErrors = req.flash 'signinErrors'
		res.render templateFolder + '/login', model

	router.get '/login/check', (req, res) ->

		model = {}
		res.render templateFolder + '/login/check', model

	router.post '/login', (req, res) ->

		auth.login req, res, (err, user) ->
			url = '/'
			if user
				if req.session.goingTo?
					url = req.session.goingTo
			else
				url = loginUrl
			res.redirect url

	router.get '/logout', (req, res) ->

		model = {}
		auth.logout req, res
		if req.body.goingTo?
			req.session.goingTo = req.body.goingTo
		res.redirect loginUrl

	router.get '/signin', (req, res) ->

		model = {}
		res.render templateFolder + '/login', model

	router.put '/signin', (req, res) ->

		model = {}
		if req.body.name? and req.body.name.full.indexOf(' ') is -1
			req.flash 'signinErrors', s("Veuillez entrer vos prénom et nom séparés d'un espace.")
			res.redirect loginUrl
		else if req.body.password isnt req.body.passwordCheck
			req.flash 'signinErrors', s("Veuillez entrer des mots de passe identiques.")
			res.redirect loginUrl
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
					if req.body.remember?
						auth.remember res, user._id
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
