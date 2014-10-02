'use strict'

NoticePackage =
	OK: 0
	ERROR: 1
	NOT_MODIFIED: 2
	LIMIT_EXEEDED: 3
	TIMEOUT: 4

	responsesToNotify: {}
	timeouts: {}

	notify: (userId, err, data) ->
		self = @
		if @responsesToNotify[userId]?
			@responsesToNotify[userId].each (id) ->
				key = userId + '-' + id
				if self.timeouts[key]
					clearTimeout self.timeouts[key]
					delete self.timeouts[key]
				@ err, data
			delete @responsesToNotify[userId]

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
		responsesToNotify = @responsesToNotify
		unless responsesToNotify[userId]?
			responsesToNotify[userId] = {}
		length = responsesToNotify[userId].length()
		for id, val of responsesToNotify[userId]
			if length-- <= config.wornet.limits.maxTabs
				break
			responsesToNotify[userId][id].call @, @LIMIT_EXEEDED, {}
			delete responsesToNotify[userId][id]
		id = (new ObjectId).toString()
		console.log id
		responsesToNotify[userId][id] = callback
		id

	waitForJson: (userId, res) ->
		res.setTimeLimit 0
		self = @
		responsesToNotify = @responsesToNotify
		id = @waitForNotification userId, (err, data = {}) ->
			if err
				data.err = err
			data.notifyStatus = if err then self.ERROR else self.OK
			res.json data
		@timeouts[userId + '-' + id] = delay config.wornet.timeout * 1000, ->
			res.json notifyStatus: @TIMEOUT
			self.remove userId, id
			delete self.timeouts[userId + '-' + id]


module.exports = NoticePackage
