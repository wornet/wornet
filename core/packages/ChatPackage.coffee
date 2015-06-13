'use strict'

ChatPackage =
	all: (req, me, next) ->
		if typeof(me) is 'function'
			next = me
			me = req.user.id
		MessageRecipient.find recipient: me, (err, messageRecipients) ->
			if err
				next err
			else
				ids = messageRecipients.column 'message'
				userIds = []
				for r in messageRecipients
					to = strval r.recipient
					unless userIds.contains to
						userIds.push to
				Message.find
					$or: [
						_id: $in: ids
					,
						author: me
					]
				, (err, messages) ->
					if err
						next err
					else
						if messages
							messageIds = (m.id for m in messages when equals m.author, me)
							MessageRecipient.find message: $in: messageIds, (err, recipients) ->
								if err
									next err
								else
									userIds.merge recipients.column('recipient').map strval
									req.getUsersByIds userIds, (err, usersMap) ->
										if err
											log
												userIds: userIds
												usersMap: usersMap
											next err
										else
											next null,
												messages.map (message) ->
													message = message.columns ['id', 'content', 'author']
													addUser = (key, id) ->
														if usersMap[id]
															message[key] = usersMap[id].publicInformations()
														else
															message.invalid = true
													if equals message.author, me
														record = recipients.findOne(message: message.id)
														if record
															addUser 'to', record.recipient || null
														else
															message.invalid = true
													else
														addUser 'from', message.author
													delete message.author
													message
												.filter (message) ->
													! message.invalid
						else
							next null, []

	list: (req, res) ->
		@all req, req.user.id, (err, chats) ->
			chatList=[]
			idList=[]
			for message in chats
				if message.from
					hashedIdOtherUser = message.from.hashedId
					otherUser = message.from
				else if message.to
					hashedIdOtherUser = message.to.hashedId
					otherUser = message.to

				message.date = Date.fromId message.id
				if !idList.contains hashedIdOtherUser
					idList.push hashedIdOtherUser
					chatList.push {otherUser:otherUser, lastMessage:message}
				else
					for chat in chatList
						if chat.otherUser.hashedId is hashedIdOtherUser
							if message.date > chat.lastMessage.date
								chat.lastMessage = message

			chatList.sort (a,b) ->
				if a.lastMessage.date < b.lastMessage.date
					1
				else if a.lastMessage.date > b.lastMessage.date
					-1
				else
					0
			res.json {chatList:chatList}


module.exports = ChatPackage
