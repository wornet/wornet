'use strict'

module.exports = (router) ->

	templateFolder = 'user'

	router.get '/login', (req, res) ->

		model = {}
		res.render templateFolder + '/login', model

	router.get '/login/check', (req, res) ->

		model = {}
		if req.session.loginForm
			delete req.session.loginForm
			model.loginErrors = req.flash 'error'
			model.loginErrors.push 'req.session.loginForm : YES'
		else
			model.signinErrors = req.flash 'error'
			model.loginErrors.push 'req.session.loginForm : NO'
		res.render templateFolder + '/login/check', model

	router.post '/login', (req, res) ->

		req.session.loginForm = true
		res.redirect '/user/login'
		# passport.authenticate('local',
		# 	successRedirect: req.session.goingTo || '/user/profile'
		# 	failureRedirect: '/user/login'
		# 	failureFlash: true
		# )(req, res)

	router.get '/logout', (req, res) ->

		model = {}
		res.render templateFolder + '/logout', model

	router.get '/signin', (req, res) ->

		model = {}
		res.render templateFolder + '/signin', model

	router.put '/signin', (req, res) ->

		model = {}
		res.render templateFolder + '/signin', model

	router.get '/forgotten-password', (req, res) ->

		model = {}
		res.render templateFolder + '/forgotten-password', model

	router.post '/forgotten-password', (req, res) ->

		model = {}
		res.render templateFolder + '/forgotten-password', model

	router.get '/profile', (req, res) ->

		model = {}
		res.render templateFolder + '/profile', model
