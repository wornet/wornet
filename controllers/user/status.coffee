'use strict'

module.exports = (router) ->

	router.post '/recent/:id', (req, res) ->
		StatusPackage.getRecentStatusForRequest req, res, req.params.id, chat: []

	router.post '/recent', (req, res) ->
		StatusPackage.getRecentStatusForRequest req, res, null, chat: []

	router.post '/and/chat/:updatedAt/:id', (req, res) ->
		StatusPackage.getRecentStatusForRequest req, res, req.params.id, null, req.params.updatedAt

	router.post '/and/chat/:updatedAt', (req, res) ->
		StatusPackage.getRecentStatusForRequest req, res, null, null, req.params.updatedAt

	router.delete '/:id', (req, res) ->
		# We cannot use findOneAndRemove because it does not execute pre-remove hook
		me = req.user._id
		next = (status) ->
			# unless equals status.author, me
			#	NoticePackage.notify [status.author], null,
			#		action: 'notice'
			#		notice: [s("{name} a supprimé un statut que vous aviez posté sur son profil.", name: req.user.fullName)]
			res.json deletedStatus: status

		switch req.params.id

			when StatusPackage.DEFAULT_STATUS_ID
				updateUser req, firstStepsDisabled: true, ->
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


	router.put '/add/:updatedAt/:id', (req, res) ->
		StatusPackage.put req, res, (status) ->
			StatusPackage.getRecentStatusForRequest req, res, req.params.id, newStatus: status, req.params.updatedAt

	router.put '/add/:updatedAt', (req, res) ->
		start = time()
		res.getRecentFinished = false
		actionLongue = (start, data) ->
			fin = time()
			if fin - start > 2000
				email = config.wornet.contact.emails.bugs
				subject = s("Post de statut anormalement long")
				message = " Voici les information recueillies:\n\n Date et Heure de début: " + date(start) +
							"\n\n Date et Heure de fin: " + date(fin) +
							"\n\n Durée création statut (en ms): " + (fin - start - 1000)
				if data.getRecentFinished
					message += "\n\n Durée getRecentStatusForRequest (en ms): " + (data.endGetRecent - start)

				message += "\n\n User: " + data.user +
							"\n\n Statut d'entrée: " + JSON.stringify(data.inputStatus, true, "\t") +
							"\n\n Statut de sortie: " + JSON.stringify(data.outputStatus, true, "\t") +
							"\n\n getRecentStatusForRequest Terminé ? " + data.getRecentFinished
				if data.getRecentFinished
					message += "\n\n Données getRecentStatusForRequest: " + JSON.stringify(data.outputStatusList, true, "\t")
				MailPackage.send email, subject, message

		StatusPackage.put req, res, (status) ->
			if config.wornet.crashlog.enabled
				delay 1000, ->
					actionLongue start,
						user: req.user
						inputStatus: req.data.status
						outputStatus: status
						getRecentFinished: res.getRecentFinished
						endGetRecent: res.endGetRecent
						outputStatusList: res.outputStatusList
			StatusPackage.getRecentStatusForRequest req, res, null, newStatus: status, req.params.updatedAt

	router.post '/', (req, res) ->
		if req.data.status and req.user
			Status.update
				_id: req.data.status._id
				author: req.user.id
			,
				content: req.data.status.content || ""
				videos: req.data.status.videos || []
				links: req.data.status.links || []
			, (err, status) ->
				if err
					res.serverError err
				else if !status
					res.serverError new PublicError s("Vous n'avez pas le droit de modifier ce statut")
				else
					res.json()
		else
			res.serverError new PublicError s('Pas de statut à modifier')

	router.get '/:id', (req, res) ->
		id = req.params.id
		if id
			Status.findOne
				_id: id
			, (err, status) ->
				if err
					res.serverError err
				else
					if StatusPackage.checkRightToSee(req, status)
						status = status.toObject()
						usersToFind = [status.author]
						if status.at is status.author
							status.at = null
						if status.at
							usersToFind.push status.at
						status.concernMe = [status.at, status.author].contains req.user.id, equals
						status.isMine = equals status.author, req.user._id
						User.find
							_id: $in: usersToFind
						, (err, users) ->
							if err
								res.serverError err
							else
								for user in users
									if equals user._id, status.author
										status.author = user.publicInformations()
									else if equals user._id, status.at
										status.at = user.publicInformations()
								PlusW.find
									status: id
								, (err, result) ->
									tabLike = []
									tabLike[id] ||= {likedByMe: false, nbLike: 0}
									for like in result
										tabLike[id].nbLike++
										if equals req.user.id, like.user
											tabLike[id].likedByMe = true
									status.likedByMe = tabLike[id].likedByMe
									status.nbLike = tabLike[id].nbLike
									status.nbImages = status.images.length
									if status.images.length
										for image in status.images
											if -1 isnt image.src.indexOf "200x"
												image.src =image.src.replace "200x", ""
									res.render 'user/status',
										status: status
					else
						res.notFound()
		else
			res.serverError new PublicError s('Pas de statut à afficher')
