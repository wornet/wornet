
waitForNotify = ->
	Ajax.get '/user/notify', (data) ->
		if data.notifications
			for notification in data.notifications
				err =  notification[0]
				notification = notification[1]
				if notification.action?
					action = notification.action || ''
					delete notification.action
				switch action
					when 'message'
						message = objectResolve notification
						users = message.users || []
						users.push message.from
						chatService.chatWith users, message
					when 'status'
						statusService.receiveStatus notification.status
					when 'askForFriend'
						s = textReplacements
						id = notification.id
						date = Date.fromId id
						friend = notification.user
						name = friend.name.full
						dataWithUser = username: '<span class="username">' + safeHtml(name) + '</span>'
						$('#asks-for-friend').append('<div class="alert alert-success friend-ask" data-id="' + id + '">' +
							'<a href="/user/profile/' + friend.hashedId + '/' + encodeURIComponent(name) + '">' +
								'<img class="thumb" src="' + friend.thumb50 + '" alt="' + safeHtml(name) + '" data-id="' + friend.hashedId + '">' +
							'</a>' +
							'<div class="shift">' +
								'<i class="date" data-date="' + date.toISOString() + '"></i>' +
								'<br>' +
								s("{username} souhaite vous ajouter à ses amis.", dataWithUser) +
								'<br>' +
								'<span class="btn accept-friend">' + s("Accepter") + '</span>' +
								'&nbsp; &nbsp;' +
								'<span class="btn ignore-friend">' + s("Ignorer") + '</span>' +
							'</div>' +
							'<div class="shift if-accepted">' +
								s("{username} fait maitnenant partie de vos amis.", dataWithUser) +
							'</div>' +
							'<div class="cb"></div>' +
						'</div>')
						notificationsService.receiveNotification [(new Date).toISOString(), notification.user, notification.id, 'askForFriend']
					when 'friendAccepted'
						friend = notification.user
						name = friend.name.full
						$('#friends').append('<li>' +
							'<a href="/user/profile/' + friend.hashedId + '/' + encodeURIComponent(name) + '">' +
								'<img src="' + friend.thumb50 + '" alt="' + safeHtml(name) + '" data-id="' + friend.hashedId + '" data-toggle="tooltip" data-placement="top" title="' + safeHtml(name) +'">' +
							'</a>' +
						'</li>')
						notificationsService.receiveNotification [(new Date).toISOString(), notification.notification]
		delay 500, waitForNotify
	null

notify = (userIds, data, success) ->
	Ajax.post '/user/notify',
		data:
			data: data
			userIds: userIds
		success: success
	null

waitForNotify()
