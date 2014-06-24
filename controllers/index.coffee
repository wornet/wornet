'use strict'

model = new IndexModel()

listUsers = (err, req, res, fromSave) ->

	User.find({},
			'name.first': 1
			'name.last': 1
			email: 1
		).sort(
			registerDate: -1
		).exec (findErr, users) ->
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
		console.log data

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
