'use strict'

UserErrors =
	INVALID_DATE: s("Veuillez entrer votre date de naissance au format jj/mm/aaaa ou aaaa-mm-jj.")
	WRONG_EMAIL: s("Cette adresse e-mail n'est pas disponible (elle est déjà prise ou la messagerie n'est pas compatible ou encore son propriétaire a demandé à ne plus recevoir d'email de notre part).")
	INVALID_PASSWORD_CONFIRM: s("Veuillez entrer des mots de passe identiques.")

inputDate = (str) ->
	str = strval(str).replace /^([0-9]+)\/([0-9]+)\/([0-9]+)$/g, '$3-$2-$1'
	new Date(str)

module.exports = (router) ->

	templateFolder = 'user'
	signinUrl = '/user/signin'

	pm = new PagesManager router, templateFolder

	# GET /user/profile > see controllers/index.coffee
	# GET /user/login > see controllers/index.coffee
	# GET /user/login (pre-signin) > see controllers/index.coffee

	router.get '/profile/:id/:name', (req, res) ->
		res.locals.friendAsked = req.flash 'friendAsked'
		UserPackage.renderProfile req, res, req.params.id

	# When user submit his e-mail and password to log in
	router.post '/login', (req, res) ->
		# Log in user
		auth.login req, res, (err, user) ->
			url = (req.goingTo() if user) || '/'
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
		# Save goingTo to return to the previous page after reconnect
		model = {}
		auth.logout req, res
		if req.body.goingTo?
			log req.body.goingTo
			req.goingTo req.body.goingTo 
		res.redirect '/'


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
		if config.wornet.mail.hostsBlackList.indexOf(req.body.email.replace(/^.*@([^@]*)$/g, '$1')) isnt -1
			req.flash 'signinErrors', UserErrors.WRONG_EMAIL
			res.redirect signinUrl
		else if req.body.password isnt req.body.passwordCheck
			req.flash 'signinErrors', UserErrors.INVALID_PASSWORD_CONFIRM
			res.redirect signinUrl
		# If no error
		else if req.body.step is "2"
			# A full name must contains a space but is not needed at the first step
			User.create
				name:
					first: req.body['name.first']
					last: req.body['name.last']
				registerDate: new Date
				email: req.body.email
				password: req.body.password
				birthDate: inputDate req.body.birthDate
			, (saveErr, user) ->
				if saveErr
					switch (saveErr.code || 0)
						when Errors.DUPLICATE_KEY
							req.flash 'signinErrors', UserErrors.WRONG_EMAIL
						else
							err = saveErr.err || strval(saveErr)
							valErr = 'ValidationError:'
							if err.indexOf(valErr) is 0
								err = s("Erreur de validation :") + err.substr(valErr.length)
								errors =
									'invalid first name': s("prénom invalide")
									'invalid last name': s("nom invalide")
									'invalid birth date': s("date de naissance invalide")
									'invalid phone number': s("numéro de téléphone invalide")
									'invalid e-mail address': s("adresse e-mail invalide")
								for code, message of errors
									err = err.replace code, message
							req.flash 'signinErrors', err
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
		hasGoingTo: (!empty(req.session.goingTo) and ['/user/profile', '/'].indexOf(req.session.goingTo) is -1)
		goingTo: req.goingTo()

	router.post '/photo', (req, res) ->
		# When user upload a new profile photo
		res.setTimeLimit 600
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
					model.src = req.user.thumb200
				done()

	router.post '/edit', (req, res) ->
		# When user edit his profile
		data = {}
		for key, val of req.body
			unless empty val
				switch key
					when 'birthDate'
						birthDate = inputDate val
						if birthDate.isValid()
							req.user.birthDate = birthDate
						else
							data.err = UserErrors.INVALID_DATE 
					when 'name.first'
						req.user.name.first = val
					when 'name.last'
						req.user.name.last = val

	# Without AJAX
	router.get '/friend/:id/:name', (req, res) ->
		# When user ask some other user for friend
		id = req.params.id
		UserPackage.askForFriend id, req, (data) ->
			if empty data.err
				req.flash 'friendAsked', s("Demande envoyée à " + escape(req.params.name))
			else
				req.flash 'profileError', s("Erreur : " + data.err)
			res.redirect '/user/profile/' + encodeURIComponent(id) + '/' + encodeURIComponent(req.params.name)

	# With AJAX
	router.post '/friend', (req, res) ->
		# When user ask some other user for friend
		UserPackage.askForFriend req.body.userId, req, res.json

	router.post '/friend/accept', (req, res) ->
		# When user accept friend ask
		UserPackage.setFriendStatus req, 'accepted', res.json

	router.post '/friend/ignore', (req, res) ->
		# When user ignore friend ask
		UserPackage.setFriendStatus req, 'refused', res.json

	router.get '/notify', (req, res) ->
		NoticePackage.waitForJson req.user.id, res

	router.post '/notify', (req, res) ->
		try
			data = req.body.data
			userId = cesarRight req.body.userId
			switch data.action || ''
				when 'message'
					data.from = req.user.publicInformations()
					data.date = new Date
					Message.create
						content: data.content
						author: req.user._id
					, (err, message) ->
						MessageRecipient.create
							message: message._id
							recipient: userId
			NoticePackage.notify userId, null, data
			res.json()
		catch err
			log err
			res.json err: err
