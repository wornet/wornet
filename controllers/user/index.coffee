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


	# GET /user/profile
	router.get '/profile', (req, res) ->
		UserPackage.renderProfile req, res

	# When user submit his e-mail and password to log in
	router.post '/login', (req, res) ->
		# Log in user
		auth.login req, res, (err, user) ->
			url = (req.goingTo() if user) || '/'
			# With AJAX, send JSON
			if req.xhr
				if err
					res.serverError err
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
					confirmUrl = config.wornet.protocole +  '://' + req.getHeader 'host'
					confirmUrl += '/user/confirm/' + user.hashedId + '/' + user.token
					MailPackage.send user.email, s("Bienvenue sur Wornet"), confirmUrl, '<a href="' + confirmUrl + '">' + s("Confirmer mon e-mail : {email}", email: user.email) + '</a>'
		else
			res.redirect signinUrl
		# res.render templateFolder + '/signin', model

	pm.page '/forgotten-password'

	pm.page '/forgotten-password', null, 'post'

	pm.page '/welcome', (req) ->
		hasGoingTo: (!empty(req.session.goingTo) and req.session.goingTo isnt '/')
		goingTo: req.goingTo()

	router.post '/profile/edit', (req, res) ->
		# When user edit his profile
		userModifications = {}
		for key, val of req.body
			unless empty val
				switch key
					when 'birthDate'
						birthDate = inputDate val
						if birthDate.isValid()
							userModifications.birthDate = birthDate
					when 'name.first'
						unless userModifications.name
							userModifications.name = req.user.name
						userModifications.name.first = val
					when 'name.last'
						unless userModifications.name
							userModifications.name = req.user.name
						userModifications.name.last = val
		extend req.user, userModifications
		extend req.session.user, userModifications
		res.redirect '/user/profile'
		User.findById req.user.id, (err, user) ->
			if user
				extend user, userModifications
				user.save (err, user) ->
					if err
						throw err
			if err
				throw err

	router.get '/notify/read/:notification', (req, res) ->
		# Delete notification when read
		req.deleteNotification req.params.id, (err, notifications) ->
			if err
				res.serverError err
			else
				res.json notifications: notifications

	router.get '/notify', (req, res) ->
		# Wait for new notifications
		NoticePackage.waitForJson req.user.id, req, res

	router.post '/notify', (req, res) ->
		# Send a notification
		try
			data = req.body.data
			userIds = (cesarRight id for id in req.body.userIds.split(','))
			switch data.action || ''
				when 'message'
					data.from = req.user.publicInformations()
					data.date = new Date
					Message.create
						content: data.content
						author: req.user._id
					, (err, message) ->
						for id in userIds
							MessageRecipient.create
								message: message._id
								recipient: id
			NoticePackage.notify userIds, null, data, true
			res.json()
		catch err
			log err
			res.serverError err

	router.get '/albums', (req, res) ->
		# Get albums list from the user logged in
		Album.find user: req.user.id, (err, albums) ->
			res.json
				err: err
				albums: albums

	# Display images in an album
	router.get '/album/:id', (req, res) ->
		done = (model) ->
			res.render templateFolder + '/album', model
		id = req.params.id
		album = null
		photos = null
		next = ->
			if album and photos
				done
					album: album
					photos: photos
		Album.findById id, (err, foundAlbum) ->
			if equals foundAlbum.user, req.user.id
				if err
					done err: err
				else
					album = foundAlbum
					next()
			else
				done err: new Error s("Cet album est privé")
		Photo.find album: id, (err, foundPhotos) ->
			if err
				done err: err
			else
				photos = foundPhotos.map (photo) ->
					photo.columns ['photo', 'name']
				next()

	router.put '/album/add', (req, res) ->
		# Create a new album
		album = extend user: req.user._id, req.body.album
		Album.create album, (err, album) ->
			album.user = cesarLeft album.user
			res.json
				err: err
				album: album

	router.put '/video/add', (req, res) ->
		# Create a new video
		video = extend user: req.user._id, req.body.video
		Video.create video, ->
			res.json()

	router.put '/link/add', (req, res) ->
		# Create a new link
		link = extend user: req.user._id, req.body.link
		Link.create link, ->
			res.json()

	router.post '/photo', (req, res) ->
		# When user upload a new profile photo
		res.setTimeLimit 600
		model = images: []
		images = req.files.photo || []
		unless images instanceof Array
			images = [images]
		unless images.length
			index = 0
			while req.files['images[' + index + ']']
				images.push req.files['images[' + index + ']']
				index++
		done = (data) ->
			model.images.push data
			if model.images.length is images.length
				res.render templateFolder + '/upload-photo', model
		lastestAlbum = null
		images.each ->
			image = @
			data = name: @name
			if image.size > config.wornet.upload.maxsize
				data.error = "size-exceeded"
				warn data.error
				done data
			else unless (['image/png', 'image/jpeg']).contains image.type
				data.error = "wrong-format"
				warn data.error
				done data
			else
				album =  req.body.album || 0
				next = ->
					addPhoto req, image, album, (err, createdAlbum = null, photo) ->
						data.createdAlbum = createdAlbum
						if err
							data.error = err
							warn err
						else
							data.src = photo.thumb200
						done data
				if album is "new"
					if lastestAlbum
						album = lastestAlbum
						next()
					else
						Album.findOne {}, {}, sort: created_at : -1, (err, foundAlbum) ->
							if err
								data.error = err
								warn err
								done data
							else
								album = foundAlbum._id
								lastestAlbum = album
								next()
				else
					next()
			true

	router.post '/first/:query', (req, res) ->
		query = req.params.query
		UserPackage.search 1, [req.user.id], query, (err, users) ->
			if err
				res.serverError err
			else
				if users.length
					user = users[0]
					res.redirect '/user/profile/' + user.hashedId + '/' + encodeURIComponent user.name.full
				else
					res.notFound()

	router.get '/search/:query', (req, res) ->
		query = req.params.query
		UserPackage.search [req.user.id], query, (err, users) ->
			if err
				res.serverError err
			else
				res.json users: users.map (user) ->
					user.publicInformations()

	router.get '/confirm/:hashedId/:token', (req, res) ->
		id = cesarRight req.params.hashedId
		if req.user._id and req.user._id isnt id
			auth.logout req, res
		User.findOneAndUpdate { _id: id, token: token }, { $set: role: 'confirmed' }, {}, (err, user) ->
			if err or ! user
				req.flash 'loginErrors', s("Votre adresse n'a pas pu être confirmée")
				warn [user, err]
			else if user
				auth.auth req, res, user
				req.flash 'profileSuccess', s("Votre adresse a bien été confirmée")
			res.redirect '/'
