'use strict'

module.exports = (router) ->

	router.get '/recent/:id', (req, res) ->
		StatusPackage.getRecentStatusForRequest req, res, req.params.id

	router.get '/recent', (req, res) ->
		StatusPackage.getRecentStatusForRequest req, res

	router.delete '/:id', (req, res) ->
		Status.findOneAndRemove
			_id: req.params.id
			$or: [
				at: req.user._id
			,
				author: req.user._id
			]
		, (err, status) ->
			if err
				res.serverError err
			else unless status
				res.serverError standartError()
			else
				status.images.each ->
					PhotoPackage.delete PhotoPackage.urlToId(@src), 'published'
					true
				unless equals status.author, req.user.id
					NoticePackage.notify [status.author], null,
						action: 'notice'
						notice: [s("{name} a supprimé un statut que vous aviez posté sur son profil.", name: req.user.fullName)]
				res.json deletedStatus: status

	router.put '/add/:id', (req, res) ->
		StatusPackage.put req, res, (status) ->
			StatusPackage.getRecentStatusForRequest req, res, req.params.id, newStatus: status

	router.put '/add', (req, res) ->
		StatusPackage.put req, res, (status) ->
			StatusPackage.getRecentStatusForRequest req, res, null, newStatus: status
