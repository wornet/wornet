'use strict'

listUsers = (err, req, res, fromSave) ->

	User.find({},
		'name.first': 1
		'name.last': 1
		email: 1
	).sort(
		registerDate: -1
	).exec (findErr, users) ->
		model = {}
		model.users = users
		if err
			model.err = err
		else if findErr
			model.err = findErr
		else if fromSave
			model.saved = true

		res.render 'index', model

module.exports = (router) ->

	router.post '/', (req, res) ->

		data = req.body

		if data.name.full.indexOf(' ') is -1
			listUsers 'Full name must contain at least 2 words', req, res, true
		else
			user = new User
				name:
					full: data.name.full
				registerDate: new Date
				email: data.email
			user.save (saveErr) ->
				listUsers saveErr, req, res, true

	router.get '/', (req, res) ->

		listUsers null, req, res


	router.get '/news', (req, res) ->

		model = {}
		res.render 'news', model


	router.get '/jobs', (req, res) ->

		model = {}
		res.render 'jobs', model


	router.get '/legals', (req, res) ->

		model = {}
		res.render 'legals', model


	alias =
		login: 'user/login'
		signin: 'user/signin'
		logout: 'user/logout'
		'forgotten-password': 'user/forgotten-password'
		profile: 'user/profile'

	for as, route of alias
		((as, route) ->
			router.get '/' + as, (req, res) ->
				res.redirect '/' + route
		)(as, route)
