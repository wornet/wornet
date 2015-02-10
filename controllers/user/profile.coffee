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
					if userModifications.password
						delete userModifications.password
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
			Photo.findOneAndUpdate { _id: userModifications.photoId }, { status: 'published' }, {}, (err, photo) ->
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
