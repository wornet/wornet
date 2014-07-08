'use strict'

model = {}

module.exports = (router) ->

	templateFolder = 'user'

	router.get '/login', (req, res) ->

		res.render templateFolder + '/login', model

	router.get '/login/check', (req, res) ->

		res.render templateFolder + '/login/check', model

	router.post '/login', (req, res) ->

		passport.authenticate('local',
			successRedirect: req.session.goingTo || '/user/profile'
			failureRedirect: '/user/login'
			failureFlash: true
		)(req, res)

	router.get '/logout', (req, res) ->

		res.render templateFolder + '/logout', model

	router.get '/signin', (req, res) ->

		res.render templateFolder + '/signin', model

	router.post '/signin', (req, res) ->

		res.render templateFolder + '/signin', model

	router.get '/forgotten-password', (req, res) ->

		res.render templateFolder + '/forgotten-password', model

	router.post '/forgotten-password', (req, res) ->

		res.render templateFolder + '/forgotten-password', model

	router.get '/profile', auth.isAuthenticated(), auth.injectUser(), (req, res) ->

		res.render templateFolder + '/profile', model
