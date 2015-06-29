'use strict'

module.exports = (router) ->

	router.get '/:at', (req, res) ->
		at = req.params.at
		# Wait for new notifications
		NoticePackage.waitForJson req.user.id, req, res, at

	router.get '', (req, res) ->
		# Wait for new notifications
		NoticePackage.waitForJson req.user.id, req, res, req.user

	router.post '', (req, res) ->
		# Send a notification
		try
			req.getFriends (err, friends, friendAsks) ->
				friendIds = friends.column 'id'
				data = req.body.data
				userIds = req.body.userIds.split(',').map(cesarRight).filter (val) ->
					friendIds.contains val
				if userIds.length > 0
					switch data.action || ''
						when 'message'
							data.from = req.user.publicInformations()
							data.date = new Date
							Message.create
								content: data.content
								author: req.user._id
							, (err, message) ->
								if err
									warn err, req
								if message
									for id in userIds
										MessageRecipient.create
											message: message._id
											recipient: id
					NoticePackage.notify userIds, null, data, true
					res.json()
				else
					err = new PublicError s("Vous ne pouvez discuter qu'avec vos amis, si vous avez envoyé une demande, il faut d'abord qu'elle soit validée.")
					res.serverError err
		catch err
			res.serverError err

	router.get '/read/:notification', (req, res) ->
		id = req.params.notification
		Notice.update
			_id: id
			user: req.user.id
		,
			status: readOrUnread.read
		, (err, notice) ->
			if err
				res.serverError err
			else if notice
				req.session.notifications = req.session.notifications
					.filter (notification) ->
						notification and notification.length
					.map (notification) ->
						if notification[0] is id
							notification.read = true
				res.json()
			else
				res.notFound()
