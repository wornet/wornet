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

	notify: (userId, err, data) ->
		self = @
		if @responsesToNotify[userId]? and @responsesToNotify[userId].length() > 0
			@responsesToNotify[userId].each (id) ->
				key = userId + '-' + id
				if self.timeouts[key]
					clearTimeout self.timeouts[key]
					delete self.timeouts[key]
				@ err, data
			delete @responsesToNotify[userId]
		else
			unless @notificationsToSend[userId]
				@notificationsToSend[userId] = {}
			id = Date.log()
			@notificationsToSend[userId][id] = [err, data]
			delay 5000, ->
				if self.responsesToNotify[userId] and self.notificationsToSend[userId][id]
					if self.responsesToNotify[userId].length() > 0
						delete self.notificationsToSend[userId][id]
					else
						delete self.notificationsToSend[userId]


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
			callback @responsesToNotify[userId].values()
			delete @notificationsToSend[userId]
			id = false
		else
			responsesToNotify = @responsesToNotify
			unless responsesToNotify[userId]?
				responsesToNotify[userId] = {}
			length = responsesToNotify[userId].length()
			for id, val of responsesToNotify[userId]
				if length-- <= config.wornet.limits.maxTabs
					break
				responsesToNotify[userId][id].call @, @LIMIT_EXEEDED, {}
				delete responsesToNotify[userId][id]

			id = Date.log()
			responsesToNotify[userId][id] = callback
		id

	waitForJson: (userId, res) ->
		res.setTimeLimit 0
		self = @
		responsesToNotify = @responsesToNotify
		id = @waitForNotification userId, (err, notifications = []) ->
			unless notifications instanceof Array
				notifications = [[err, notifications]]
			data = notifications: notifications
			if err
				data.err = err
			data.notifyStatus = if err then self.ERROR else self.OK
			res.json data
		if id
			@timeouts[userId + '-' + id] = delay config.wornet.timeout * 1000, ->
				res.json notifyStatus: @TIMEOUT
				self.remove userId, id
				delete self.timeouts[userId + '-' + id]


module.exports = NoticePackage
