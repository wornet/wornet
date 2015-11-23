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
							tabToIgnore = messageObj.message.tabToIgnore
							data = messageObj.message.data
							noticeId = messageObj.message.noticeId
							if NoticePackage.responsesToNotify[userId]
								each NoticePackage.responsesToNotify[userId], (id) ->
									key = userId + '-' + id
									NoticePackage.clearTimeout key
									# say to other nodes that this notification is already responded
									redisClientEmitter.publish config.wornet.redis.defaultChannel,
										JSON.stringify(
											type: "deleteNotifToSend",
											message:
												userId: userId,
												noticeId: noticeId,
										)
									if NoticePackage.respond @, err, data, tabToIgnore
										delete NoticePackage.responsesToNotify[userId][noticeId]
								unless count NoticePackage.responsesToNotify[userId]
									delete NoticePackage.responsesToNotify[userId]
							else
								unless NoticePackage.notificationsToSend[userId]
									NoticePackage.notificationsToSend[userId] = {}
								NoticePackage.notificationsToSend[userId][noticeId] = [err, data]
					when "respondWaiter"
						place = messageObj.message.place
						err = messageObj.message.err
						notifications = messageObj.message.notifications
						Waiter.respond place, err, notifications, true
					when "deleteNotifToSend"
						userId = messageObj.message.userId
						noticeId = messageObj.message.noticeId
						if NoticePackage.notificationsToSend[userId] and NoticePackage.notificationsToSend[userId][noticeId]
							if NoticePackage.notificationsToSend[userId].getLength() > 0
								delete NoticePackage.notificationsToSend[userId][noticeId]
							else
								delete NoticePackage.notificationsToSend[userId]
						true
					when "addPhoto"
						PhotoPackage.photos[messageObj.message.photoId] = messageObj.message.token
					when "deletePhoto"
						PhotoPackage.delete messageObj.message.photoId
			else
				warn new serverError("missformed message")
