'use strict'

syncUserPhotos = (userModifications, photo) ->
	userModifications.photoId = photo.id
	userModifications.photo = photo.photo
	userModifications.thumb = photo.thumb
	for size in config.wornet.thumbSizes
		userModifications['thumb' + size] = photo['thumb' + size]
	userModifications

module.exports = (router) ->

	router.get '', (req, res) ->
		res.redirect '/' + req.user.uniqueURLID
		# UserPackage.renderProfile req, res

	router.get '/:id/:name', (req, res) ->
		cache 'publicAccountByHashedId', (publicAccountByHashedId) ->
			if publicAccountByHashedId[req.params.id]
				res.redirect '/' + publicAccountByHashedId[req.params.id]
			else
				User.findOne
					_id: cesarRight req.params.id
				, (err, user) ->
					cache 'publicAccountByHashedId', (publicAccountByHashedId, done) ->
						publicAccountByHashedId[req.params.id] = user.uniqueURLID
						done publicAccountByHashedId
					, ->
						res.redirect '/' + user.uniqueURLID
		# res.locals.friendAsked = req.flash 'friendAsked'
		# UserPackage.renderProfile req, res, req.params.id

	router.post '/edit', (req, res) ->
		# When user edit his profile
		userModifications = UserPackage.getUserModificationsFromRequest req
		next = ->
			updateUser req, userModifications, (err) ->
				if err
					req.flash 'profileErrors', err
				res.redirect '/' + req.user.uniqueURLID
			###
			User.findById req.user.id, (err, user) ->
				if user
					extend user, userModifications
					user.save (err, user) ->
						if err
							throw err
				if err
					throw err
			###
		if userModifications.photoId
			where = _id: userModifications.photoId
			values = status: 'published'
			options = safe: true
			Photo.findOneAndUpdate where, values, options, (err, photo) ->
				if ! err and photo
					Album.findOne
						_id: photo.album
					, (err, album) ->
						if !err and album
							UserAlbums.touchAlbum req.user, album._id, (err, result) ->
								if err
									warn err
							album.refreshPreview done
					done = ->
						PhotoPackage.forget req, photo.id
						syncUserPhotos userModifications, photo
				else
					req.flash 'profileErrors', s("La photo a expirée, veuillez la ré-envoyer.")
					delete userModifications.photoId
				next()
		else
			next()

	router.post '/photo', (req, res) ->
		photoId = req.data.photoId

		if photoId
			end = (photo) ->
				PhotoPackage.forget req, photo.id
				data = album: photo.album
				updateUser req, syncUserPhotos(data, photo), (err) ->
					if err
						res.serverError err
					else
						res.json src: photo.photo

			parallel
				album: (done) ->
					data =
						user: req.user._id
					if req.user.photoAlbumId
						data._id = req.user.photoAlbumId
					else
						data.name = photoDefaultName()
					Album.findOne data, (err, album) ->
						if !err and album
							done null, album
						else
							done err
				photo: (done) ->
					Photo.findOne
						_id: photoId
					, (err, photo) ->
						if !err and photo
							done null, photo
						else
							done err
				, (results) ->
					if equals results.photo.album, results.album.id
						end results.photo
					else
						addPhoto req, results.photo, null, (err, album, newPhoto) ->
							if err
								res.serverError err
							else
								Photo.findOneAndUpdate
									_id: newPhoto._id
								,
									status: "published"
								,
									safe: true
								, (err, photo) ->
									if err
										res.serverError err
									else
										album.refreshPreview (err) ->
											if err
												warn err
										end photo
				, (err) ->
					res.serverError err
		else
			res.serverError new PublicError s('Aucune photo selectionnée.')

	router.put "/follow", (req, res) ->
		userId = req.data.id
		if userId
			isAPublicAccount req, userId, true, (isAPublicAccount) ->
				if isAPublicAccount and req.user
					Follow.create
						follower: req.user.id
						followed: cesarRight userId
					, (err, follow) ->
						warn err if err
						res.json()
				else
					res.serverError new PublicError s('Seuls les comptes publics peuvent être suivis.')
		else
			res.serverError new PublicError s('Personne à suivre.')


	router.delete "/follow", (req, res) ->
		userId = req.data.id
		if userId
			Follow.remove
				follower: req.user.id
				followed: cesarRight userId
			, (err, follow) ->
				warn err if err
				res.json()
		else
			res.serverError new PublicError s('Personne à unfollow.')
