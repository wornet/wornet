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
		UserPackage.renderProfile req, res

	router.get '/:id/:name', (req, res) ->
		res.locals.friendAsked = req.flash 'friendAsked'
		UserPackage.renderProfile req, res, req.params.id

	router.post '/edit', (req, res) ->
		# When user edit his profile
		userModifications = UserPackage.getUserModificationsFromRequest req
		next = ->
			updateUser req, userModifications, (err) ->
				if err
					req.flash 'profileErrors', err
				res.redirect '/user/profile'
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
				updateUser req, syncUserPhotos({}, photo), (err) ->
					if err
						res.serverError err
					else
						res.redirect './'
						# res.json src: photo.photo

			parallel
				album: (done) ->
					Album.findOne
						user: req.user._id
						name: photoDefaultName()
					, (err, album) ->
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
						addPhoto req, photo, null, (err, album, newPhoto) ->
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
										end photo
				, (err) ->
					res.serverError err
		else
			res.serverError new PublicError s('Aucune photo selectionnée.')
