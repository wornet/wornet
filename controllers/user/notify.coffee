'use strict'

module.exports = (router) ->

	router.get '/:at', (req, res) ->
		if req.user
			at = req.params.at
			# Wait for new notifications
			NoticePackage.waitForJson req.user.id, req, res, at
		else
			delay 2.minutes, ->
				res.json()

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
					notice = {}
					notice.action = "notice"
					notice.author = data.from
					notice.notice = [
						jd('img(src=user.thumb50 alt=user.name.full data-id=user.hashedId data-toggle="tooltip" data-placement="top" title=user.name.full).thumb', user: data.from) +
						jd 'span(data-href="/") ' +
							s("{username} vous a envoyé un message.", username: data.from.name.full)
					]
					notice.notice.push 'chatMessage'
					NoticePackage.notify userIds.with(req.user.id), null, notice, true, req.getHeader 't'
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

	router.get '/list/all', (req, res) ->
		req.user.getFriends (err, friends, friendAsks) ->
			if err
				res.serverError err
			else
				friendsThumb = friends.copy().pickUnique config.wornet.limits.friendsOnProfile
				isMe = true
				res.render 'user/notification-list',
					isMe: isMe
					numberOfFriends: friends.length
					friends: if isMe then friendsThumb else []
					friendAsks: if isMe then friendAsks else {}

	router.post '/list/:id', (req, res) ->
		where = {
			user: req.user._id
			type: $ne: "chatMessage"
		}.with if req.params.id
			_objectId = req.params.id
			if /^[0-9a-fA-F]{24}$/.test _objectId
				_id: $lt: new ObjectId(_objectId).path

		limit = if req.param.id
			config.wornet.limits.scrollNoticePageCount
		else
			config.wornet.limits.noticePageCount

		Notice.find where
		.sort _id: 'desc'
		.limit limit
		.exec (err, notices) ->
			if err
				res.serverError err
			else
				usersTofind = notices.column('launcher').unique()
				userThumb = []
				User.find
					_id: $in: usersTofind
				, (err, users) ->
					warn err if err
					for user in users
						userThumb[user._id] = user.thumb50
					notices = notices.map (notice) ->
						notice = notice.toObject()
						notice.content = notice.content.replace /\/img\/photo\/([0-9]+x)?([0-9a-z]+).*\.jpg/ig, userThumb[notice.launcher]
						notice.date = Date.fromId notice._id
						notice
					res.json notices: notices
