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
											console.log me
											next null, messages.map (message) ->
												message = message.columns ['id', 'content', 'author']
												addUser = (key, id) ->
													message[key] = usersMap[id].publicInformations()
												if equals message.author, me
													addUser 'to', recipients.findOne(message: message.id).recipient
												else
													addUser 'from', message.author
												delete message.author
												message
						else
							next null, []

module.exports = ChatPackage
