
waitForNotify = ->
	Ajax.get '/user/notify', (data) ->
		console.log data
		delay 500, waitForNotify

notify = (userId, data) ->
	Ajax.post '/user/notify', data:
		data: data
		userId: userId
