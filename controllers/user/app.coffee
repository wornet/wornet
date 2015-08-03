'use strict'

module.exports = (router) ->

	templateFolder = 'user/app'

	pm = new PagesManager router, templateFolder

	# When user submit his e-mail and password to log in
	pm.page '', (req, res, done) ->
		App.find user: req.user.id, (err, apps) ->
			if err
				res.serverError err
			else
				done
					apps: apps
					appAlerts: req.getAlerts 'app'

	router.put '/add', (req, res) ->
		data = extend req.data.columns(['name', 'description', 'url']),
			user: req.user.id
		App.create data, (err, app) ->
			if err
				req.flash 'appErrors', s("Veuillez renseigner tous les champs.")
			else
				req.flash 'appSuccess', s("L'application {name} a été créée avec succès.", name: app.name)
			res.redirect '/user/app'

	router.post '/:id', (req, res) ->
		where =
			_id: req.params.id
			user: req.user.id
		set = req.data.columns ['name', 'description', 'url']
		App.findOneAndUpdate where, set, (err, app) ->
			if err
				req.flash 'appErrors', s("Veuillez renseigner tous les champs.")
			else
				req.flash 'appSuccess', s("L'application {name} a été modifiée avec succès.", name: app.name)
			res.redirect '/user/app'


	router.delete '/:id', (req, res) ->
		data =
			_id: req.params.id
			user: req.user.id
		App.findOne data, (err, app) ->
			if err
				res.serverError err
			else if app
				app.remove (err) ->
					if err
						res.serverError err
					else
						res.json()
			else
				res.notFound()
