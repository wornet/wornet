'use strict'

module.exports = (router) ->


	new PagesManager router
		.page '/newsroom'
		.page '/jobs'
		.page '/legals'


	# Temporary fix of /undefined request
	router.get '/undefined', (req, res) ->
		res.end ''

	# When login/signin/profile page displays
	router.get '/', (req, res) ->
		if req.user
			# GET /
			UserPackage.renderHome req, res
		else
			# GET /user/login (and pre-signin)
			# Get errors in flash memory (any if AJAX is used and works on client device)
			res.render 'user/login',
				loginAlerts: req.getAlerts 'login' # Will be removed when errors will be displayed on the next step


	# Report a non-appropriated content
	router.get '/report/:status', (req, res) ->
		if req.xhr
			res.json()
		else
			res.render 'report'
		id = req.params.status
		Status.findById id, (err, status) ->
			if status
				message = 'Un contenu a été signalé par ' + req.user.fullName + '. L\'id du contenu est : ' + id + '<br>Contenu :<br>' + status.content
				MailPackage.send config.wornet.mail.reportTo, "[Wornet] Contenu signalé", message, (err, info) ->
					if err
						throw err
					else
						console['log'] info

	alias =
		'user/login': ''
		signin: 'user/signin'
		logout: 'user/logout'
		'forgotten-password': 'user/forgotten-password'
		profile: 'user/profile'

	for as, route of alias
		do (as, route) ->
			router.get '/' + as, (req, res) ->
				res.redirect '/' + route
