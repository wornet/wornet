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
					NoticePackage.notify userIds.with(req.user.id), null, data, true, req.getHeader 't'
					res.json()
				else
					err = new PublicError s("Vous ne pouvez discuter qu'avec vos amis, si vous avez envoyé une demande, il faut d'abord qu'elle soit validée.")
					res.serverError err
		catch err
			res.serverError err

	router.get '/read/:notification', (req, res) ->
		id = req.params.notification
		NoticePackage.readNotice req, id, false, (err, result) ->
			if err
				res.serverError err
			else
				res.json()

	router.post '/read/all', (req, res) ->
		NoticePackage.readNotice req, null, true, (err, result) ->
			if err
				res.serverError err
			else
				res.json()
