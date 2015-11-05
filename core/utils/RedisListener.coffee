'use strict'

module.exports = ->
	redisClientReciever.on 'message', (channel, message) ->
		messageObj = JSON.parse message
		if channel is config.wornet.redis.defaultChannel and "object" is typeof messageObj
			if messageObj.type
				switch messageObj.type
					when "hasWaiter"
						if messageObj.message.userId
							userId = messageObj.message.userId
							err = messageObj.message.err
							if NoticePackage.responsesToNotify[userId]
								each NoticePackage.responsesToNotify[userId], (id) ->
									key = userId + '-' + id
									NoticePackage.clearTimeout key
									if NoticePackage.respond @, err, data, tabToIgnore
										delete NoticePackage.responsesToNotify[userId][id]
								unless count NoticePackage.responsesToNotify[userId]
									delete NoticePackage.responsesToNotify[userId]
							else
								unless NoticePackage.notificationsToSend[userId]
									NoticePackage.notificationsToSend[userId] = {}
								id = uniqueId()
								NoticePackage.notificationsToSend[userId][id] = [err, data]
								delay 5.seconds, ->
									if NoticePackage.responsesToNotify[userId] and NoticePackage.notificationsToSend[userId] and NoticePackage.notificationsToSend[userId][id]
										if NoticePackage.responsesToNotify[userId].getLength() > 0
											delete NoticePackage.notificationsToSend[userId][id]
										else
											delete NoticePackage.notificationsToSend[userId]
									true
					when "respondWaiter"
						place = messageObj.message.place
						err = messageObj.message.err
						notifications = messageObj.message.notifications
						Waiter.respond place, err, notifications, true
			else
				warn new serverError("missformed message")
