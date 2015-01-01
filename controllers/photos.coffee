'use strict'

module.exports = (router) ->

	if config.env.development

		router.get '/', (req, res) ->

			model = {}
			Photo.find user: req.user.id
				.sort
					album: 'desc'
					createdAt: 'desc'
				.select 'name thumb photo album createdAt'
				.exec (err, photos) ->
					if err
						model.err = err
					else
						model.photos = photos
					res.render 'photos', model
