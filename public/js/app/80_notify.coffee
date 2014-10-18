
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
		delay 500, waitForNotify

notify = (userIds, data, success) ->
	Ajax.post '/user/notify',
		data:
			data: data
			userIds: userIds
		success: success

waitForNotify()
