'use strict'

NoticePackage =
	OK: 0
	ERROR: 1
	NOT_MODIFIED: 2
	LIMIT_EXEEDED: 3
	TIMEOUT: 4

	# Is a user (identified by id) waiting for notifications (and so present)
	isPresent: (userId) ->
		sharedData.responsesToNotify[userId]?

	# Are users (identifed by ids array) present
	arePresents: (userIds) ->
		userIds.filter (id) ->
			@isPresent id

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
				place: data.notice[4]
			, (err, notice) ->
				if err
					warn err
				done err, notice.id
		else
			done()

	notifyPlace: (place, err, data) ->
		Waiter.respond place, err, data

	clearTimeout: (key) ->
		if sharedData.timeouts[key]
			clearTimeout sharedData.timeouts[key]
			delete sharedData.timeouts[key]

	respond: (callback, err, data, tabToIgnore) ->
		if callback instanceof Waiter
			if callback.req and tabToIgnore and tabToIgnore is callback.req.getHeader 't'
				return false
			callback.respond err, data
		else
			callback err, data
		true

	# Send a notification to users
	notify: (userIds, err, groupData, appendOtherUsers = false, tabToIgnore) ->
		self = @
		# stack = (new Error()).stack
		aMonthAgo = (new Date).subMonths config.wornet.limits.monthsBeforeRemoveNotice
		id = Math.floor(aMonthAgo.getTime() / 1000).toString(16) + "0000000000000000"
		Notice.remove
			_id: $lt: id
		, (err, count) ->
			warn err if err
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
							if sharedData.responsesToNotify[userId]?
								each sharedData.responsesToNotify[userId], (id) ->
									key = userId + '-' + id
									self.clearTimeout key
									if self.respond @, err, data, tabToIgnore
										delete sharedData.responsesToNotify[userId][id]
								unless count sharedData.responsesToNotify[userId]
									delete sharedData.responsesToNotify[userId]
							else
								unless sharedData.notificationsToSend[userId]
									sharedData.notificationsToSend[userId] = {}
								id = uniqueId()
								sharedData.notificationsToSend[userId][id] = [err, data]
								delay 5.seconds, ->
									if sharedData.responsesToNotify[userId] and sharedData.notificationsToSend[userId] and sharedData.notificationsToSend[userId][id]
										if sharedData.responsesToNotify[userId].getLength() > 0
											delete sharedData.notificationsToSend[userId][id]
										else
											delete sharedData.notificationsToSend[userId]
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
				if ! err and notices
					for notice in notices
						notice.remove()

	# Delete a notification if id is specified or all the notifications to a user if not
	remove: (userId, id = null) ->
		if sharedData.responsesToNotify[userId]?
			if id isnt null
				if sharedData.responsesToNotify[userId][id]?
					if sharedData.responsesToNotify[userId][id] instanceof Waiter
						sharedData.responsesToNotify[userId][id].unwatch()
					delete sharedData.responsesToNotify[userId][id]
					if empty sharedData.responsesToNotify[userId]
						delete sharedData.responsesToNotify[userId]
			else
				each sharedData.responsesToNotify[userId], ->
					if @ instanceof Waiter
						@unwatch()
				delete sharedData.responsesToNotify[userId]

			# is this remove is a real leave of a user?
			delay (config.wornet.timeout / 2).seconds, =>
				if !@isPresent userId
					sharedData.userWhoHasLeft.push userId
					User.update
						_id: userId
					,
						lastLeave: new Date()
					, (err, res) ->
						warn err if err

	# Register an action to do when a user receive a notification
	waitForNotification: (userId, callback) ->
		if sharedData.notificationsToSend[userId]
			@respond callback, null, sharedData.notificationsToSend[userId].values()
			delete sharedData.notificationsToSend[userId]
			id = false
		else
			responsesToNotify = sharedData.responsesToNotify
			unless responsesToNotify[userId]?
				responsesToNotify[userId] = {}
				if sharedData.userWhoHasLeft.contains userId
					delay (config.wornet.timeout / 2).seconds, =>
						delete sharedData.userWhoHasLeft[userId]
						User.update
							_id: userId
						,
							lastLeave: null
						, (err, res) ->
							warn err if err
			length = responsesToNotify[userId].getLength()
			for id, val of responsesToNotify[userId]
				if length-- <= config.wornet.limits.maxTabs
					break
				@respond responsesToNotify[userId][id], @LIMIT_EXEEDED, {}
				delete responsesToNotify[userId][id]

			id = uniqueId()
			responsesToNotify[userId][id] = callback
		id

	# Register a response to wich send JSON data when a user receive a notification
	waitForJson: (userId, req, res, watchPlace = null) ->
		res.setTimeLimit 0
		self = @
		responsesToNotify = sharedData.responsesToNotify
		req.session.save (err) ->
			if err
				throw err

			waiter = new Waiter userId, watchPlace, req, res
			id = self.waitForNotification userId, waiter
			if id
				waiter.timeoutKey = userId + '-' + id
				sharedData.timeouts[waiter.timeoutKey] = delay config.wornet.timeout.seconds, ->
					req.session.reload (err) ->
						res.json
							notifyStatus: sharedData.TIMEOUT
							loggedFriends: req.getLoggedFriends()
						self.remove userId, id
						delete sharedData.timeouts[waiter.timeoutKey]

	readNotice: (req, id, all, done) ->
		if !all and !id
			done new PublicError s("L'id ne peut être vide si on ne traite pas toutes les notifications")
		where = user: req.user.id
		.with if !all
		    _id: id

		Notice.update where,
			status: readOrUnread.read
		,
			multi: true
		, (err, notice) ->
			if err
				done err
			else if notice
				req.session.notifications = req.session.notifications
					.filter (notification) ->
						notification and notification.length
					.map (notification) ->
						if all or notification[0] is id
							notification.read = true
				done()
			else
				done new PublicError s("Notification non trouvée.")


module.exports = NoticePackage
