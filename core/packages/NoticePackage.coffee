'use strict'

NoticePackage =
	OK: 0
	ERROR: 1
	NOT_MODIFIED: 2
	LIMIT_EXEEDED: 3
	TIMEOUT: 4

	responsesToNotify: {}
	notificationsToSend: {}
	timeouts: {}

	isPresent: (userId) ->
		@responsesToNotify[userId]?

	arePresents: (userIds) ->
		userIds.filter (id) ->
			@isPrsent id

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


	remove: (userId, id = null) ->
		if @responsesToNotify[userId]?
			if id isnt null
				if @responsesToNotify[userId][id]?
					list = []
					for callback, i in @responsesToNotify[userId]
						if i isnt id
							list.push callback
					if list.length
						@responsesToNotify[userId] = list
					else
						delete @responsesToNotify[userId]
			else
				delete @responsesToNotify[userId]

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

	waitForJson: (userId, req, res) ->
		res.setTimeLimit 0
		self = @
		responsesToNotify = @responsesToNotify
		id = @waitForNotification userId, (err, notifications = []) ->
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
			@timeouts[userId + '-' + id] = delay config.wornet.timeout.seconds, ->
				res.json
					notifyStatus: self.TIMEOUT
					loggedFriends: (req.user.friends || []).find present: true
				self.remove userId, id
				delete self.timeouts[userId + '-' + id]


module.exports = NoticePackage
