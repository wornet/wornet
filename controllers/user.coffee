'use strict'

module.exports = (router) ->

	templateFolder = 'user'
	loginUrl = '/user/login'
	signinUrl = '/user/signin'

	pm = new PagesManager router, templateFolder

	# When login/signin page displays
	pm.page '/login', (req) ->
		# Get errors in flash memory (any if AJAX is used and works on client device)
		loginErrors: req.flash 'loginErrors' # Will be removed when errors will be displayed on the next step


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
			# Direct redirect to profile if ask for root
			if url is '/'
				url = '/user/profile'
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


	# When signin step 2 page displays
	pm.page '/signin', (req) ->
		# Get errors in flash memory (any if AJAX is used and works on client device)
		signinErrors: req.flash 'signinErrors' # Will be removed when errors will be displayed on the next step

	# When user submit his e-mail and password to sign in
	router.put '/signin', (req, res) ->

		model = {}
		# A full name must contains a space but is not needed at the first step
		# if req.body.name? and req.body.name.full.indexOf(' ') is -1
		# 	req.flash 'signinErrors', s("Veuillez entrer vos prénom et nom séparés d'un espace.")
		# 	res.redirect signinUrl
		# Passwords must be identic
		wrongEmail = s("Cette adresse e-mail n'est pas disponible (elle est déjà prise ou la messagerie n'est pas compatible ou encore son propriétaire a demandé à ne plus recevoir d'email de notre part).")
		log config.wornet.mail['hosts-black-list']
		if config.wornet.mail['hosts-black-list'].indexOf(req.body.email.replace(/^.*@([^@]*)$/g, '$1')) isnt -1
			req.flash 'signinErrors', wrongEmail
			res.redirect signinUrl
		else if req.body.password isnt req.body.passwordCheck
			req.flash 'signinErrors', s("Veuillez entrer des mots de passe identiques.")
			res.redirect signinUrl
		# If no error
		else if req.body.step is "2"
			req.body.birthDate = strval(req.body.birthDate).replace /^([0-9]+)\/([0-9]+)\/([0-9]+)$/g, '$3-$2-$1'
			birthDate = new Date(req.body.birthDate)
			# A full name must contains a space but is not needed at the first step
			if !birthDate.isValid()
				req.flash 'signinErrors', s("Veuillez entrer votre date de naissance au format jj/mm/aaaa ou aaaa-mm-jj.")
				res.redirect signinUrl
			else
				User.create 
					name:
						first: req.body['name.first']
						last: req.body['name.last']
					registerDate: new Date
					email: req.body.email
					password: req.body.password
					birthDate: birthDate
				, (saveErr, user) ->
					if saveErr
						log saveErr
						switch (saveErr.code || 0)
							when Errors.DUPLICATE_KEY
								req.flash 'signinErrors', wrongEmail
							else
								req.flash 'signinErrors', (saveErr.err || strval(saveErr))
						res.redirect signinUrl
					else
						# if "Se souvenir de moi" est coché
						if req.body.remember?
							auth.remember res, user._id
						# Put user in session
						auth.auth req, res, user
						url = '/user/welcome'
						res.redirect if user then '/user/welcome' else signinUrl
		else
			res.redirect signinUrl
		# res.render templateFolder + '/signin', model

	pm.page '/forgotten-password'

	pm.page '/forgotten-password', null, 'post'

	pm.page '/welcome', (req) ->
		hasGoingTo: (!empty(req.session.goingTo) and req.session.goingTo isnt '/user/profile')
		goingTo: req.session.goingTo

	pm.page '/profile'

	router.post '/photo', (req, res) ->

		model = {}
		done = ->
			res.render templateFolder + '/upload-photo', model
		if req.files.photo.size > config.wornet.upload.maxsize
			model.error = "size-exceeded"
			done()
		else if (['image/png', 'image/jpeg']).indexOf(req.files.photo.type) is -1
			model.error = "wrong-format"
			done()
		else
			addPhoto req, 0, (err) ->
				if err
					model.error = err
				else
					model.src = req.user.thumb
				done()
