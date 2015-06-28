'use strict'

module.exports = (router) ->

	router.get '/recent/:id', (req, res) ->
		StatusPackage.getRecentStatusForRequest req, res, req.params.id, chat: []

	router.get '/recent', (req, res) ->
		StatusPackage.getRecentStatusForRequest req, res, null, chat: []

	router.get '/and/chat/:id', (req, res) ->
		StatusPackage.getRecentStatusForRequest req, res, req.params.id

	router.get '/and/chat', (req, res) ->
		StatusPackage.getRecentStatusForRequest req, res

	router.delete '/:id', (req, res) ->
		# We cannot use findOneAndRemove because it does not execute pre-remove hook
		me = req.user._id
		next = (status) ->
			unless equals status.author, me
				NoticePackage.notify [status.author], null,
					action: 'notice'
					notice: [s("{name} a supprimé un statut que vous aviez posté sur son profil.", name: req.user.fullName)]
			res.json deletedStatus: status

		switch req.params.id

			when StatusPackage.DEFAULT_STATUS_ID
				req.user.firstStepsDisabled = true
				req.session.user.firstStepsDisabled = true
				updateUser req.user, firstStepsDisabled: true, ->
				res.json()

			else
				Status.findOne
					_id: req.params.id
					$or: [
						at: me
					,
						author: me
					]
				, (err, status) ->
					if err
						res.serverError err
					else unless status
						res.serverError standartError()
					else
						status.remove (err) ->
							if err
								res.serverError err
							else
								StatusPackage.updatePoints req, status, status.author, false, ->
									next status


	router.put '/add/:id', (req, res) ->
		StatusPackage.put req, res, (status) ->
			StatusPackage.getRecentStatusForRequest req, res, req.params.id, newStatus: status

	router.put '/add', (req, res) ->
		StatusPackage.put req, res, (status) ->
			StatusPackage.getRecentStatusForRequest req, res, null, newStatus: status
