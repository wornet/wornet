'use strict'

NoticePackage =
	OK: 0
	ERROR: 1
	NOT_MODIFIED: 2
	LIMIT_EXEEDED: 3
	TIMEOUT: 4

	# Pending requests until receive a new notification
	responsesToNotify: {}
	# Pending notifications until users recipient ask for receive it
	notificationsToSend: {}
	# Notifications disapear after some time if they are not received
	timeouts: {}

	# Is a user (identified by id) waiting for notifications (and so present)
	isPresent: (userId) ->
		@responsesToNotify[userId]?

	# Are users (identifed by ids array) present
	arePresents: (userIds) ->
		userIds.filter (id) ->
			@isPrsent id

	# Execute the callback only if the data is for everyone
	# or if sender is a best friend of the receiver
	dataForBestFriends: (userId, data, done) ->
		if data.forBestFriends and data.author
			where =
				_id: userId
				bestFriends: data.author.hashedId
			User.count where, (err, count) ->
				if err
					warn err
				if count
					done()
		else
			done()

	# Create a notice in the DB if the data contains some
	createNotice: (userId, data, done) ->
		if data.notice
			Notice.create
				user: userId
				content: data.notice[0]
			, (err, notice) ->
				if err
					warn err
				done err, notice.id
		else
			done()

	# Send a notification to users
	notify: (userIds, err, groupData, appendOtherUsers = false) ->
		self = @
		Notice.remove created_at: $lt: (new Date).subMonths 6
		userIds.each ->
			userId = strval @
			data = groupData.copy()
			self.dataForBestFriends userId, data, ->
				self.createNotice userId, data, (err, noticeId) ->
					if noticeId
						data.id = noticeId
					if appendOtherUsers
						otherUserIds = userIds.filter (id) ->
							id isnt userId
					done = ->
						if self.responsesToNotify[userId]? and self.responsesToNotify[userId].getLength() > 0
							self.responsesToNotify[userId].each (id) ->
								key = userId + '-' + id
								if self.timeouts[key]
									clearTimeout self.timeouts[key]
									delete self.timeouts[key]
								@ err, data
								true
							delete self.responsesToNotify[userId]
						else
							unless self.notificationsToSend[userId]
								self.notificationsToSend[userId] = {}
							id = (new Date).log()
							self.notificationsToSend[userId][id] = [err, data]
							delay 5.seconds, ->
								if self.responsesToNotify[userId] and self.notificationsToSend[userId] and self.notificationsToSend[userId][id]
									if self.responsesToNotify[userId].getLength() > 0
										delete self.notificationsToSend[userId][id]
									else
										delete self.notificationsToSend[userId]
								true
						true
					if appendOtherUsers and otherUserIds.length
						User.find _id: $in: otherUserIds, (err, users) ->
							if err
								log err
							else
								data.users = (user.publicInformations() for user in users)
							done()
					else
						done()
		true

	# Delete a notification if id is specified or all the notifications to a user if not
	remove: (userId, id = null) ->
		if @responsesToNotify[userId]?
			if id isnt null
				if @responsesToNotify[userId][id]?
					delete @responsesToNotify[userId][id]
					if empty @responsesToNotify[userId]
						delete @responsesToNotify[userId]
			else
				delete @responsesToNotify[userId]

	# Register an action to do when a user receive a notification
	waitForNotification: (userId, callback) ->
		if @notificationsToSend[userId]
			#callback null, @responsesToNotify[userId].values()
			callback null, @notificationsToSend[userId].values()
			delete @notificationsToSend[userId]
			id = false
		else
			responsesToNotify = @responsesToNotify
			unless responsesToNotify[userId]?
				responsesToNotify[userId] = {}
			length = responsesToNotify[userId].getLength()
			for id, val of responsesToNotify[userId]
				if length-- <= config.wornet.limits.maxTabs
					break
				responsesToNotify[userId][id].call @, @LIMIT_EXEEDED, {}
				delete responsesToNotify[userId][id]

			id = (new Date).log()
			responsesToNotify[userId][id] = callback
		id

	# Register a response to wich send JSON data when a user receive a notification
	waitForJson: (userId, req, res) ->
		res.setTimeLimit 0
		self = @
		responsesToNotify = @responsesToNotify
		req.session.save (err) ->
			if err
				throw err

			id = self.waitForNotification userId, (err, notifications = []) ->
				req.session.reload (sessErr) ->
					if sessErr
						throw sessErr
					unless notifications instanceof Array
						notifications = [[err, notifications]]
					mustRefreshFriends = false
					for notification in notifications
						if notification[1]
							if notification[1].askForFriend?
								test = hashedId: notification[1].askForFriend.hashedId
								unless (req.session.friendAsks || {}).has(test) or (req.session.friends || []).has(test)
									req.cacheFlush 'friends'
									req.user.friendAsks[notification[1].id] = notification[1].askForFriend
									req.session.user.friendAsks = req.user.friendAsks
									req.session.friendAsks = req.user.friendAsks
								delete notification[1].askForFriend
							if notification[1].userId?
								delete notification[1].userId
							if notification[1].deleteFriendAsk?
								delete req.user.friendAsks[notification[1].deleteFriendAsk]
								req.session.user.friendAsks = req.user.friendAsks
								req.session.friendAsks = req.user.friendAsks
								req.session.notifications = (req.session.notifications || []).filter (data) ->
									if typeof data[1] isnt 'object' or typeof data[1].hashedId is 'undefined'
										true
									else
										data[1].hashedId isnt cesarRight userId
								delete notification[1].deleteFriendAsk
							if notification[1].addFriend?
								req.addFriend notification[1].addFriend
								delete notification[1].addFriend
					data =
						notifications: notifications
						loggedFriends: req.getLoggedFriends()
					data.notifyStatus = if err then self.ERROR else self.OK
					if err
						data.err = err
					req.refreshNotifications (notifications) ->
						if notifications.length
							req.session.notifications = notifications
						req.session.save (err) ->
							if err
								throw err
							res.json data
			if id
				self.timeouts[userId + '-' + id] = delay config.wornet.timeout.seconds, ->
					req.session.reload (err) ->
						res.json
							notifyStatus: self.TIMEOUT
							loggedFriends: req.getLoggedFriends()
						self.remove userId, id
						delete self.timeouts[userId + '-' + id]


module.exports = NoticePackage
