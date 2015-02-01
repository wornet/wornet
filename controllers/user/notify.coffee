'use strict'

module.exports = (router) ->

	router.get '', (req, res) ->
		# Wait for new notifications
		NoticePackage.waitForJson req.user.id, req, res

	router.post '', (req, res) ->
		# Send a notification
		try
			req.getFriends (err, friends, friendAsks) ->
				friendIds = friends.column 'id'
				data = req.body.data
				userIds = (cesarRight id for id in req.body.userIds.split(',')).filter (val) ->
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
		# Delete notification when read
		###
		req.deleteNotification req.params.id, (err, notifications) ->
			if err
				res.serverError err
			else
				res.json notifications: notifications
		###
