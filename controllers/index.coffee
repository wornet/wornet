'use strict'

model = new IndexModel()

listUsers = (err, req, res) ->

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
			else
				model.saved = true

			res.render 'index', model

module.exports = (router) ->

	router.post '/', (req, res) ->

		data = req.body
		console.log data

		kyle = new User
			name:
				full: data.name.full
			registerDate: new Date
			email: data.email
		kyle.save (saveErr) ->
			listUsers saveErr, req, res

	router.get '/', (req, res) ->

		listUsers null, req, res
