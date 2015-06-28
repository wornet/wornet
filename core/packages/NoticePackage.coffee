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
				type: data.notice[1]
				launcher: data.notice[2]
				attachedStatus: data.notice[3]
			, (err, notice) ->
				if err
					warn err
				done err, notice.id
		else
			done()

	notifyPlace: (place, err, data) ->
		Waiter.respond place, err, data

	clearTimeout: (key) ->
		if @timeouts[key]
			clearTimeout @timeouts[key]
			delete @timeouts[key]

	respond: (callback, err, data) ->
		if callback instanceof Waiter
			callback.respond err, data
		else
			callback err, data

	# Send a notification to users
	notify: (userIds, err, groupData, appendOtherUsers = false) ->
		self = @
		Notice.remove created_at: $lt: (new Date).subMonths 6
		userIds.each ->
			userId = strval @
			if /^[0-9a-f]+$/ig.test userId
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
									self.clearTimeout key
									self.respond @, err, data
								delete self.responsesToNotify[userId]
							else
								unless self.notificationsToSend[userId]
									self.notificationsToSend[userId] = {}
								id = uniqueId()
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

	unnotify: (groupData) ->
		if groupData.action is 'notice' and groupData.notice
			notice = groupData.notice
			Notice.find
				type: notice.type
				launcher: notice.launcher
				attachedStatus: notice.status
			, (err, notices) ->
				if err or !notices
					true
				else
					for notice in notices
						notice.remove()

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
			@respond callback null, @notificationsToSend[userId].values()
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

			id = uniqueId()
			responsesToNotify[userId][id] = callback
		id

	# Register a response to wich send JSON data when a user receive a notification
	waitForJson: (userId, req, res, watchPlace = null) ->
		res.setTimeLimit 0
		self = @
		responsesToNotify = @responsesToNotify
		req.session.save (err) ->
			if err
				throw err

			waiter = new Waiter userId, watchPlace, req, res
			id = self.waitForNotification userId, waiter
			if id
				waiter.timeoutKey = userId + '-' + id
				self.timeouts[userId + '-' + id] = delay config.wornet.timeout.seconds, ->
					req.session.reload (err) ->
						res.json
							notifyStatus: self.TIMEOUT
							loggedFriends: req.getLoggedFriends()
						self.remove userId, id
						delete self.timeouts[userId + '-' + id]


module.exports = NoticePackage
