'use strict'

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
			updateUser req.user, userModifications, (err) ->
				if err
					req.flash 'profileErrors', err
				else
					extend req.user, userModifications
					extend req.session.user, userModifications
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
					userModifications.photoId = photo.id
					userModifications.photo = photo.photo
					userModifications.thumb = photo.thumb
					for size in config.wornet.thumbSizes
						userModifications['thumb' + size] = photo['thumb' + size]
					PhotoPackage.forget req, photo.id
				else
					req.flash 'profileErrors', s("La photo a expirée, veuillez la ré-envoyer.")
					delete userModifications.photoId
				next()
		else
			next()

	router.post '/photo', (req, res) ->
		photoId = req.data.photoId

		end = (user, newSrc) ->
			delete user._id
			extend req.user, user
			extend req.session.user, user
			req.cacheFlush 'user'
			res.json src: newSrc.substr(newSrc.indexOf('/img'))

		if photoId
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
				, photo: (done) ->
					Photo.findOne
						_id: photoId
					, (err, photo) ->
						if !err and photo
							done null, photo
						else
							done err
				, (results) ->
					photo = results.photo.toObject()
					photo.path = __dirname + '/../../public/img/photo/' + photo._id + '.jpg'
					if equals results.photo.album, results.album.id
						User.findOneAndUpdate
							_id: req.user._id
						,
							photoId: photoId
						, (err, user) ->
							if err
								warn err
							else
								end user.toObject(), photo.path
					else
						addPhoto req, photo, null, (err, album, newPhoto) ->
							if err
								res.serverError err
							else
								parallel
									user: (done) ->
										User.findOneAndUpdate
											_id: req.user._id
										,
											photoId: newPhoto._id
										, (err, user) ->
											if err
												done err
											else
												done null, user
									, photo: (done) ->
										Photo.findOneAndUpdate
											_id: newPhoto._id
										,
											status: "published"
										,(err, photo) ->
											if !err and photo
												done null, photo
											else
												done err
									, (results) ->
										end results.user.toObject(), photo.path
									, (err) ->
										res.serverError err
				, (err) ->
					res.serverError err
		else
			res.serverError new PublicError s('Aucune photo selectionnée.')
