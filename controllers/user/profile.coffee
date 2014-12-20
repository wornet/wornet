'use strict'

module.exports = (router) ->

	router.get '', (req, res) ->
		UserPackage.renderProfile req, res

	router.get '/:id/:name', (req, res) ->
		res.locals.friendAsked = req.flash 'friendAsked'
		UserPackage.renderProfile req, res, req.params.id

	router.post '/edit', (req, res) ->
		# When user edit his profile
		userModifications = {}
		for key, val of req.body
			if empty val
				val = null
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
				when 'photoId'
					if PhotoPackage.allowedToSee req, val
						userModifications.photoId = val
				when 'maritalStatus', 'loveInterest'
					unless User.schema.path(key).enumValues.contains val
						val = null
					userModifications[key] = val
				when 'city', 'birthCity', 'job', 'jobPlace', 'biography'
					userModifications[key] = val
		next = ->
			extend req.user, userModifications
			extend req.session.user, userModifications
			updateUser req.user, userModifications, ->
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
					req.flash 'profileError', s("La photo a expirée, veuillez la ré-envoyer.")
					delete userModifications.photoId
				next()
		else
			next()
