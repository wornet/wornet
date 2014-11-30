Controllers =

	Calendar: ($scope) ->
		# Crud handle create, remove, update and get utils for /agenda URL
		agenda = new Crud '/agenda'
		date = new Date()
		d = date.getDate()
		m = date.getMonth()
		y = date.getFullYear()


		# Get events list from the controller (passed through the template)
		events = getData 'events'
		# Copy titles of each event in eventsTitles
		eventsTitles = {}
		for event in events
			# Swap MongoDB _id to id key in event object
			if event._id?
				event.id = event._id
			eventsTitles[event.id] = event.title
		$scope.events = events


		# Preapre an event before sending (get required columns and transform dates).
		getEvent = (event) ->
			data = {}
			for key in 'id user title content url start end allDay'.split /\s/g
				if event[key]?
					data[key] = event[key]
					if data[key] instanceof Date
						data[key] = (new Date(data[key].getTime() - (data[key].getTimezoneOffset() * 60000))).toISOString()
			data


		###
		When an event is modified, saveEvent is triggered, this function will not
		send AJAX request immediatly but 500 milliseconds later, if another modification
		occured until this delay for the same event, the request will be cancelled and
		replaced by the new one. So we do not send too many request only one after user
		modify an event then stop modify it more than 500 milliseconds.
		###
		saveDelays = {}
		$scope.saveEvent = (event, cb) ->
			if saveDelays[event.id]?
				clearTimeout saveDelays[event.id]
			saveDelays[event.id] = delay 500, ->
				# AJAX POST request to /agenda URL
				agenda.post
					data:
						event: getEvent event
					success: (data) ->
						delete saveDelays[event.id]
						if cb? and typeof(data) is 'object' and data.event
							cb data.event
						return
				return
			return


		# On click on an event, a modal bootstrap window displays allowing user to
		# enter a description content
		$scope.editContent = (event, allDay, jsEvent, view) ->
			$scope.eventToEdit = $.extend {}, event
			$('#eventContent').modal()
			return


		# When user save the event description content
		$scope.saveContent = (event, allDay, jsEvent, view) ->
			for ev, index in $scope.events
				if ev.id is event.id
					ev.content = event.content
					$scope.saveEvent ev
					break
			return


		# When user type a name for a new event or existing event
		$scope.rename = (event) ->
			# If the name changed
			if event.title isnt eventsTitles[event.id]
				# Save new data (new name)
				$scope.saveEvent event, (data) ->
					# After saving
					# If no error
					if typeof(data) is 'object' && typeof(data.err) is 'undefined'
						# Update eventsTitles with the new name
						eventsTitles[event.id] = event.title
					return
			return


		# On add a new event
		$scope.addEvent = ->
			# Default beginning : tomorrow 14H
			start = new Date(y, m, d + 1)
			start.setHours(14)
			# Default ending : tomorrow 16H
			end = new Date(y, m, d + 1)
			end.setHours(16)
			# Create the new event object
			event =
				title: ""
				start: start
				end: end
				allDay: false
			# Add to event list
			$scope.events.push event
			# AJAX PUT request to /agenda URL
			agenda.put
				data:
					event: getEvent event
				success: (data) ->
					if typeof(data) is 'object' and data.event
						event.id = data.event._id
					return
			# After new field is ready (after AngularJS create it)
			delay 50, ->
				# Give the focus to the new field
				$('ul.events input[ng-model="e.title"]:last').focus()
				return
			return


		# On delete an event
		$scope.remove = (event) ->
			for ev, index in $scope.events
				if ev.id is event.id
					$scope.events.splice index, 1
					break
			# AJAX PUT request to /agenda URL
			agenda.delete
				data:
					event: getEvent event
			return


		# When switch to day/week/month mode
		$scope.changeView = (view, calendar) ->
			calendar.fullCalendar "changeView", view
			return


		# Init calendar
		$scope.renderCalender = (calendar) ->
			calendar.fullCalendar "render"
			return


		# Append config options to date texts and giv the all things
		# to the calendar User Interface Configuration
		$scope.uiConfig = calendar: $.extend(
			{
				lang: "fr"
				height: 450
				editable: true
				header:
					left: "title"
					center: ""
					right: "today prev,next"

				eventClick: (event) ->
					$scope.editContent event
				eventDrop: (event) ->
					$scope.saveEvent event
				eventResize: (event) ->
					$scope.saveEvent event
			}
			dateTexts
		)


		# Take event source at event list get from the controller
		# (passed through the template)
		$scope.eventSources = [$scope.events]

		return

	Chat: ($scope) ->
		$('#chat').show()
		chats = getChats()
		$scope.chats = chats

		$scope.$on 'chatWith', (e, users, message) ->
			modified = false
			ids = (user.hashedId for user in users)
			id = ids.join ','
			if chats[id]
				currentChat = chats[id]
				unless chats[id].open
					chats[id].open = true
					modified = true
			else
				currentChat =
					open: true
					users: users
					messages: []
				chats[id] = currentChat
				modified = true
			if chat.minimized?
				delete chat.minimized
				modified = true
			if message
				currentChat.messages.push message
				modified = true
			if modified
				saveChats chats
			refreshScope $scope
			return

		$scope.close = (chat) ->
			chat.open = false
			saveChats chats
			return

		$scope.send = (message, id) ->
			chatData =
				date: new Date
				content: message.content
			postData =
				action: 'message'
				content: message.content
			chats[id].messages.push chatData
			notify id, postData, ->
				chatData.ok = true
			message.content = ""
			saveChats chats
			return

		$scope.minimize = (chat) ->
			chat.minimized = !(chat.minimized || false)
			saveChats chats
			return

		return

	Login: ($scope) ->
		keepTipedModel $scope, '#login', 'user'
		# Get remember preference of the user if previously saved (default: true)
		$scope.user.remember = (if localStorage and typeof(localStorage['user.remember']) isnt 'undefined' then !!localStorage['user.remember'] else true)
		# When the form is submitted
		$scope.submit = (user) ->
			# Save remember preference of the user
			if localStorage
				localStorage['user.remember'] = user.remember
			# send a POST request to /user/login with user.email and user.password
			Ajax.post '/user/login',
				data: user
				success: (data) ->
					# If get a redirection
					if data.goingTo
						Ajax.page data.goingTo
					# Else : an error occured
					else
						$('#loginErrors').errors data.err
					return
			return
		$('#login').on 'submit', prevent

		return

	Medias: ($scope) ->
		getAlbums (err, albums) ->
			unless err
				$scope.albums = albums
				refreshScope $scope
			return

		return

	MediaView: ($scope) ->
		$scope.loadMedia = (type, media) ->
			console.log [@, arguments]
			media.type = type
			if type is 'image'
				media.src = (media.src || media.photo).replace(/\/[0-9]+x([^\/]+)$/g, '/$1')
			$scope.loadedMedia = media
			delay 1000, ->
				$('#status-view iframe[data-ratio]').ratio()
			refreshScope $scope
			return

		window.loadMedia = (type, media) ->
			$scope.loadMedia type, media
			return

		return

	Notifications: ($scope) ->
		$scope.notifications = {}

		$scope.$on 'receiveNotification', (e, notification) ->
			$scope.notifications[notification.id] = notification
			refreshScope $scope
			delay 1, refreshPill
			return

		$scope.$on 'setNotifications', (e, notifications) ->
			$scope.notifications = notifications
			refreshScope $scope
			delay 1, refreshPill
			return

		return

	Profile: ($scope, chatService) ->
		$scope.chatWith = (user) ->
			chatService.chatWith [objectResolve user]
			return

		return

	Search: ($scope) ->
		$scope.search = (query) ->
			query.content = ''
			return

		ajaxRequest = null

		$scope.change = (query) ->
			query.action = '/user/first/' + query.content
			if ajaxRequest
				ajaxRequest.abort()
			ajaxRequest = Ajax.get '/user/search/' + encodeURIComponent tquery.content, (data) ->
				if data.users
					query.users = data.users
					$scope.apply()
			return

		return

	SigninFirstStep: ($scope) ->
		keepTipedModel $scope, '#signin', 'user'
		saveUser $scope

		return

	SigninSecondStep: ($scope) ->
		user = $.parseJSON sessionStorage['user']
		$scope.user = user
		saveUser $scope

		return

	Status: ($scope) ->
		setRecentStatus = (data) ->
			if data.recentStatus and typeof data.recentStatus is 'object' and data.recentStatus.length
				$scope.recentStatus = data.recentStatus
				refreshScope $scope
			return

		at = getData 'at'

		Ajax.get '/user/status/recent' + (if at then '/' + at else ''), setRecentStatus

		getAlbums (err, albums) ->
			unless err
				$scope.albums = albums
				refreshScope $scope
			return

		window.statusScope = $scope
		$scope.$on 'receiveStatus', (e, status) ->
			$scope.recentStatus.unshift status
			refreshScope $scope
			return

		$scope.status = containsMedias: false
		$scope.media = step: null

		initMedias = ->
			$scope.medias =
				links: []
				images: []
				videos: []
			return

		$scope.containsMedias = (status) ->
			status.containsMedias = true
			initMedias()
			$scope.media.step = null
			return

		$scope.selectAlbum = (album) ->
			$scope.currentAlbum = $.extend {}, album
			initMedias()
			$scope.media.step = 'add'
			return

		$scope.createAlbum = (album) ->
			delete sessionStorage['albums']
			Ajax.put '/user/album/add',
				data:
					album: album
			$scope.selectAlbum album
			$scope.albums.push $scope.currentAlbum
			album =
				name: ''
				description: ''
			return

		$scope.addMedia = (link) ->
			href = link.href
			match = href.match /src="([^"]+)"/g
			if match and match.length > 1
				href = match[1]
			https = href.substr(0, 5) is 'https'
			href = href
				.replace /^(https?)?:?\/\//, ''
				.replace /^www\./, ''
			video = (->
				videoHosts =
					'//www.dailymotion.com/embed/video/$1': [/^dai\.ly\/([a-z0-9_-]+)/, /^dailymotion\.com\/video\/([a-z0-9_-]+)/i]
					'//www.youtube.com/embed/$1': [/^youtu\.be\/([a-z0-9_-]+)/, /^youtube\.com\/watch\?v=([a-z0-9_-]+)/i]
				for url, regexps of videoHosts
					for regexp in regexps
						match = href.match regexp
						if match and match.length > 1
							return url.replace '$1', match[1]
				null
			)()
			if video
				$scope.medias.videos.push
					href: video
			else
				$scope.medias.links.push
					href: href
					https: https
			link.href = ''

			return

		$scope.send = (status) ->
			Ajax.put '/user/status/add',
				data:
					status: status
					at: at
					medias: $scope.medias || null
				success: setRecentStatus
			status.content = ""
			initMedias()

			return

		$scope.loadMedia = (type, media) ->
			loadMedia type, media

			return

		return

	Welcome: ($scope) ->
		delete sessionStorage['user']
		$('iframe.player').removeClass('hidden')
		$(window).trigger('resize')

		return
