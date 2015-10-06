'use strict'

ChatPackage =
	all: (req, next) ->
		@where req, {}, next

	where: (req, where, next) ->
		me = req.user.id
		MessageRecipient.find extend(recipient: me, where), (err, messageRecipients) ->
			if err
				next err
			else
				ids = messageRecipients.column 'message'
				userIds = []
				for r in messageRecipients
					to = strval r.recipient
					unless userIds.contains to
						userIds.push to
				Message.find (extend $or: [
						_id: $in: ids
					,
						author: me
					], where
				), (err, messages) ->
					if err
						next err
					else
						if messages
							messageIds = (m.id for m in messages when equals(m.author, me) and !m.maskedFor.contains me)
							MessageRecipient.find (extend message: $in: messageIds, where), (err, recipients) ->
								if err
									next err
								else
									# if we have received a message and we have never respond
									# so, the chat go only in one direction
									userRecipient = recipients.column('recipient').map strval
									for mess in messages
										if ids.contains(mess.id, equals) and !userRecipient.contains(mess.author) and !mess.maskedFor.contains me, equals
											userIds.push mess.author

									userIds.merge userRecipient

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
														message.new = req.user.lastLeave and req.user.lastLeave < Date.fromId message.id
													delete message.author
													message
												.filter (message) ->
													! message.invalid
												.sort (a,b) ->
													da = Date.fromId a.id
													db = Date.fromId b.id
													if da > db
														1
													else if da < db
														-1
													else
														0
						else
							next null, []

	list: (req, res) ->
		@all req, (err, chats) ->
			chatList = []
			idList = []
			for message in chats
				if message.from
					hashedIdOtherUser = message.from.hashedId
					otherUser = message.from
				else if message.to
					hashedIdOtherUser = message.to.hashedId
					otherUser = message.to

				message.date = Date.fromId message.id
				if message.content.length > 140
					message.content = message.content.substr(0, 140) + '...'
				if !idList.contains hashedIdOtherUser
					idList.push hashedIdOtherUser
					chatList.push
						otherUser: otherUser
						lastMessage: message
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
			res.json {chatList: chatList}

	mask: (req, res, otherUserHashedId) ->
		messagesToMask = []
		otherUserId = cesarRight otherUserHashedId
		me = req.user.id
		_warn = (err) ->
			if err
				warn err
		MessageRecipient.find
			$or: [
				recipient: me
			,
				recipient: otherUserId
			], (err, messageRecipients) ->
				_warn err
				if messageRecipients
					idsMessagesRecipe = messageRecipients.column 'message'
					Message.find
						$or: [
							author: otherUserId
						,
							author: me
						]
						_id: $in: idsMessagesRecipe
					, (err, messages) ->
						_warn err
						if messages
							for message in messages
								message.maskedFor ||= []
								if message.maskedFor.contains otherUserId
									parallelRemove [
										Message
										_id: message.id
									], [
										MessageRecipient
										message: message.id
									], _warn
								else unless message.maskedFor.contains me
									message.maskedFor.push me
									Message.update
										_id: message.id
									,
										$set:
											maskedFor: message.maskedFor
									, _warn

		res.json()

module.exports = ChatPackage
