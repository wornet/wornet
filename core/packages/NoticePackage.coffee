'use strict'

NoticePackage =
	OK: 0
	ERROR: 1
	NOT_MODIFIED: 2
	LIMIT_EXEEDED: 3
	TIMEOUT: 4

	responsesToNotify: {}

	notify: (userId, err, data) ->
		if @responsesToNotify[userId]?
			@responsesToNotify[userId].each ->
				@ err, data
			delete @responsesToNotify[userId]

	remove: (userId, id = null) ->
		if @responsesToNotify[userId]?
			if id isnt null
				if @responsesToNotify[userId][id]?
					delete [id]
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
			responsesToNotify[userId] = []
		if responsesToNotify[userId].length > config.wornet.limits.maxTabs
			responsesToNotify[userId].shift().call @, @LIMIT_EXEEDED, {}
		self = @
		id = responsesToNotify[userId].length
		responsesToNotify[userId][id] = callback err, data
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
		delay config.wornet.timeout, ->
			res.json notifyStatus: @TIMEOUT
			self.remove userId, id


module.exports = NoticePackage
