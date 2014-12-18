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

	# Send a notification to users
	notify: (userIds, err, groupData, appendOtherUsers = false) ->
		self = @
		userIds.each ->
			userId = strval @
			data = groupData.copy()
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
					id = Date.log()
					self.notificationsToSend[userId][id] = [err, data]
					delay 5000, ->
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
				warn 'Maximum of tabs exeeded'
				responsesToNotify[userId][id].call @, @LIMIT_EXEEDED, {}
				delete responsesToNotify[userId][id]

			id = Date.log()
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
				req.session.reload (err) ->
					if err
						throw err
					unless notifications instanceof Array
						notifications = [[err, notifications]]
					for notification in notifications
						if notification[1]
							if notification[1].userId?
								delete notification[1].userId
							if notification[1].deleteFriendAsk?
								delete req.user.friendAsks[notification[1].deleteFriendAsk]
								req.session.user.friendAsks = req.user.friendAsks
								req.session.user.notifications = req.session.user.notifications.filter (data) ->
									if typeof data[1] isnt 'object' or typeof data[1].hashedId is 'undefined'
										true
									else
										data[1].hashedId isnt cesarRight userId
								req.user.notifications = notifications
								delete notification[1].deleteFriendAsk
							if notification[1].addFriend?
								req.addFriend notification[1].addFriend
								delete notification[1].addFriend
					data = notifications: notifications
					data.notifyStatus = if err then self.ERROR else self.OK
					if err
						data.err = err
					res.json data
			if id
				self.timeouts[userId + '-' + id] = delay config.wornet.timeout.seconds, ->
					req.session.reload (err) ->
						res.json
							notifyStatus: self.TIMEOUT
							loggedFriends: (req.user.friends || []).find present: true
						self.remove userId, id
						delete self.timeouts[userId + '-' + id]


module.exports = NoticePackage
