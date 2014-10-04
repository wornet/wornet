
waitForNotify = ->
	Ajax.get '/user/notify', (data) ->
		if data.notifications
			for notification in data.notifications
				err =  notification[0]
				notification = notification[1]
				console.log notification
				switch notification.action || ''
					when 'message'
						message = objectResolve notification
						console.log message
						chatService.chatWith message.from, message
		delay 500, waitForNotify

notify = (userId, data, success) ->
	Ajax.post '/user/notify',
		data:
			data: data
			userId: userId
		success: success

waitForNotify()
