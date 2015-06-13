Controllers =

	Album: ($scope) ->

		$scope.update = (album) ->

			Ajax.post 'user/album/'+album.id,
				data: album
				success: (data) ->
					getAlbumsFromServer (err, albums) ->
						return
					return

			if album.name
				album.name.edit = false
			if album.description
				album.description.edit = false
			refreshScope $scope
		return


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

	Chat: ($scope, $sce) ->
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
				saveChatState currentChat
				saveChats chats
			refreshScope $scope
			return

		$scope.$on 'all', (e, messages = []) ->
			chats = getChats()
			messageDates = []
			usersToChats = {}
			for id, chat of chats
				for user in chat.users
					usersToChats[user.hashedId] = id
				for message in chat.messages
					messageDates.push message.date
			for message in messages
				message.date = Date.fromId message.id
				delete message.id
				if messageDates.indexOf(message.date) is -1
					if message.from
						unless usersToChats[message.from.hashedId]
							usersToChats[message.from.hashedId] = message.from.hashedId
							chats[message.from.hashedId] =
								users: [message.from]
								messages: []
						chat = chats[usersToChats[message.from.hashedId]]
						chat.messages.push message
						loadChatState chat
					else if message.to
						unless usersToChats[message.to.hashedId]
							usersToChats[message.to.hashedId] = message.to.hashedId
							chats[message.to.hashedId] =
								users: [message.to]
								messages: []
						chat = chats[usersToChats[message.to.hashedId]]
						chat.messages.push message
						loadChatState chat
			$scope.chats = saveChats chats
			refreshScope $scope
			return

		$scope.close = (chat) ->
			chat.open = false
			saveChatState chat
			saveChats chats
			return

		$scope.send = (message, id) ->
			if message.content and message.content.length
				chatData =
					date: new Date
					content: message.content
				postData =
					action: 'message'
					content: message.content
				chats[id].messages.push chatData
				notify id, postData, ->
					chatData.ok = true
					return
				message.content = ""
				saveChats chats
			return

		$scope.press = ($event, message, id) ->
			if $event.keyCode is 13
				$scope.send message, id
				cancel $event
			else
				true

		$scope.minimize = (chat) ->
			chat.minimized = !(chat.minimized || false)
			saveChatState chat
			saveChats chats
			return

		if ! exists('[ng-controller="StatusCtrl"]') and exists('[ng-controller="Chat"]')
			Ajax.get '/user/chat', (data) ->
				chatService.all data.chat
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
		$scope.selectAlbum = (album) ->
			location.href = '/user/album/' + album._id
			return

		window.setMediaAlbums = (albums) ->
			$scope.albums = albums
			refreshScope $scope
			return

		window.refreshMediaAlbums = ->
			getAlbumsFromServer (err, albums) ->
				unless err
					setMediaAlbums albums
				return
			return

		getAlbums (err, albums) ->
			unless err
				setMediaAlbums albums
			return

		return

	MediaViewer: ($scope) ->

		getPrev = ->
			if $scope.loadedMedia.album
				photos = $scope.loadedMedia.album.photos
				if photos and photos.length > 1
					prev = null
					for photo in photos
						if photo.id is $scope.loadedMedia.id
							return prev
						prev =
							src: photo.photo
							name: photo.name
			null

		getNext = ->
			if $scope.loadedMedia.album
				photos = $scope.loadedMedia.album.photos
				if photos and photos.length > 1
					prevId = null
					for photo in photos
						if prevId is $scope.loadedMedia.id
							next =
								src: photo.photo
								name: photo.name
							return next
						prevId = photo.id
			null

		$scope.inFade = (action) ->
			$children = $ '#media-viewer > * > *'
			$children.fadeOut 100, ->
				action()
				delay 20, ->
					$children.fadeIn 100
					return
				return
			return

		$scope.prev = ->
			if prev = getPrev()
				$scope.inFade ->
					$scope.loadMedia 'image', prev
				return
			return

		$scope.next = ->
			if next = getNext()
				$scope.inFade ->
					$scope.loadMedia 'image', next
				return
			return

		deletableMedia = null
		$scope.deleteMedia = ->
			if deletableMedia
				$('#media-viewer [data-dismiss]:first').click()
				s = textReplacements
				bootbox.confirm s("Êtes-vous sûr de vouloir supprimer ce média de son album et de son statut ?"), (ok) ->
					if ok
						media = $.extend {}, deletableMedia
						key = (media.type || 'image') + 's'
						if media.mediaId and media.statusId
							for i, status of statusScope.recentStatus
								if status._id is media.statusId and status[key]
									status[key] = status[key].filter (val) ->
										val._id isnt media.mediaId
							refreshScope statusScope
						showLoader()
						Ajax.delete '/user/media',
							data: media
							success: ->
								deletableMedia = null
								if media.mediaId
									delay 600, refreshMediaAlbums
								else
									location.reload()
								hideLoader()
							error: ->
								serverError()
								hideLoader()
					return
			return

		$scope.loadMedia = (type, media, concernMe) ->
			media = $.extend
				concernMe: concernMe
				first: true
				last: true
			, media
			media.type = type
			if type is 'image'
				media.src = (media.src || media.photo).replace /\/[0-9]+x([^\/]+)$/g, '/$1'
				id = idFromUrl media.src
			deletableMedia =
				id: id
				type: type
				statusId: media.statusId || null
				mediaId: media._id || null
			testSize = ->
				$mediaViewer = $ '#media-viewer'
				$img = $mediaViewer.find 'img.big'
				if $img.length
					$mediaViewer
						.find 'img.big, a.next, a.prev'
						.css 'max-height', Math.max(200, window.innerHeight - 200) + 'px'
					w = $img.width()
					h = $img.height()
					if w * h
						between = (min, max, number) ->
							Math.max min, Math.min max, Math.round number
						$mediaViewer.find('.img-buttons')
							.css 'margin-top', -h
							.width w
						$mediaViewer.find('.img-buttons, .prev, .next').height h
						$mediaViewer.find('.prev, .next')
							.width Math.round w / 2
							.css 'line-height', (h + between 0, 20, h / 2 - 48) + 'px'
							.css 'font-size', between 16, 64, (Math.min w / 2, h / 2) - 10
					else
						delay 200, testSize
				return
			if id
				$.extend media,
					date: Date.fromId(id).toISOString()
					id: id
				Ajax.get '/user/photo/' + id, (data) ->
					if data.user
						if data.album and data.album.photos
							photos = data.album.photos
							if photos.length > 1
								photos.sort (a, b) ->
									if a.id > b.id
										-1
									else if a.id < b.id
										1
									else
										0
								if id isnt photos[0].id
									media.first = false
								if id isnt photos[photos.length - 1].id
									media.last = false
								delay 100, ->
									if next = getNext()
										img = new Image
										img.onload = ->
											if prev = getPrev()
												(new Image).src = prev.src
										img.src = next.src

						$.extend media, data
						refreshScope $scope
						delay 10, testSize
					return
			else
				delay 10, testSize
			$scope.loadedMedia = media
			delay 1000, ->
				$('#media-viewer iframe[data-ratio]').ratio()
				return
			refreshScope $scope
			return

		window.loadMedia = (type, media, concerMe) ->
			$scope.loadMedia type, media, concerMe
			delay 1, ->
				$('#media-viewer').modal()
				return
			return

		return

	Notifications: ($scope, notificationsService, $sce) ->
		$scope.notifications = {}

		$scope.ifId = (id, defaultValue) ->
			if /^[0-9a-fA-F]+$/g.test id
				id
			else
				defaultValue

		$scope.trust = (html) ->
			$sce.trustAsHtml html

		$scope.$on 'receiveNotification', (e, notification) ->
			id = notification.id || notification[0]
			unless $scope.notifications[id]
				$scope.notifications[id] = notification
				refreshScope $scope
				delay 1, refreshPill
			return

		$scope.$on 'setNotifications', (e, notifications) ->
			$scope.notifications = notifications
			refreshScope $scope
			delay 1, refreshPill
			return

		return

	Navbar: ($scope) ->

		$scope.openChatList = ->
			Ajax.get '/user/chat/list', (chat) ->
				$scope.chatList = chat.chatList
				refreshScope $scope

				$('.selector-chat-list').show()
				bootbox.dialog(
					message: $('.selector-chat-list').html()
					title: "Messagerie"
				)
				$('.selector-chat-list:first').hide()

		return

	Profile: ($scope, chatService) ->
		$scope.chatWith = (user) ->
			chatService.chatWith [objectResolve user]
			return

		$scope.deleteFriend = (id) ->
			Ajax.delete '/user/friend',
				data: id: id
				success: ->
					location.reload()
			return

		$scope.deletePhoto = ($event) ->
			Ajax.delete '/user/photo'
			$($event.target)
				.parents('[ng-controller]:first')
				.find('.upload-thumb')
				.prop('src', '/img/default-photo.jpg')

		loadNewIFrames()

		return

	Search: ($scope) ->
		$scope.chatWith = (user) ->
			chatService.chatWith [objectResolve user]
			$scope.query.action = '#'
			$scope.query.content = ''
			$scope.query.users = []
			refreshScope $scope
			return

		$scope.search = (query) ->
			query.content = ''
			return

		ajaxRequest = null

		$scope.change = (query) ->
			if ajaxRequest
				ajaxRequest.abort()
			if query.content.length > 0
				query.action = '/user/first/' + query.content
				ajaxRequest = Ajax.get '/user/search/' + encodeURIComponent query.content
				.done (data) ->
					if data.users
						$scope.query.users = data.users
						refreshScope $scope
			else
				$scope.query.users = []
				query.action = '#'
			return

		if ~((window.navigator || {}).userAgent || '').indexOf('Safari/')
			delay 1, ->
				$('#search').hide()
				delay 1, ->
					$('#search').show()

		return

	SigninFirstStep: ($scope) ->
		keepTipedModel $scope, '#signin', 'user'
		saveUser $scope

		return

	SigninSecondStep: ($scope) ->
		try
			user = $.parseJSON sessionStorage['user']
		catch e
		if user
			if user.birthDate
				user.birthDate = new Date user.birthDate
			$scope.user = user
		saveUser $scope
		$scope.user ||= {}
		unless $scope.user.email
			value = $('input[ng-model="user.email"]').attr 'value'
			if value
				$scope.user.email = value

		return

	Head: ($scope) ->
		$scope.$on 'enableSmilies', (e, enabled) ->
			$scope.smilies = enabled

	Status: ($scope, smiliesService) ->

		initMedias = ->
			$scope.medias =
				links: []
				images: []
				videos: []
			return

		$scope.removeMedia = (media) ->
			Ajax.delete '/user/media/preview',
				data: media
				success: (data)->
					if data.id
						if data.type is "image"
							for image, index in $scope.medias.images
								if image and image.id is data.id
									$scope.medias.images.splice index, 1
						else if data.type is "video"
							for video, index in $scope.medias.videos
								if video and video.id is data.id
									$scope.medias.videos.splice index, 1
						else if data.type is "link"
							for link, index in $scope.medias.links
								if link and link.id is data.id
									$scope.medias.links.splice index, 1
						$('.tab .medias img[src="'+data.src+'"]').parent().remove()
					else
						location.reload()
					hideLoader()
				error: ->
					serverError()
					hideLoader()


		scanLink = (href, sendMedia = true) ->
			https = href.substr(0, 5) is 'https'
			href = href.replace /^(https?)?:?\/\//, ''
			test = href.replace /^www\./, ''
			video = do ->
				for url, regexps of videoHosts
					for regexp in regexps
						match = test.match regexp
						if match and match.length > 1
							return url.replace '$1', match[1]
				null
			s = textReplacements
			if video
				if sendMedia
					$scope.medias.videos.push
						href: video
					Ajax.put '/user/video/add', video: url: video
					return
				else
					# '<a href=' + JSON.stringify(video) + '>' + s("Voir la vidéo") + '</a>'
					''
			else
				if sendMedia
					$scope.medias.links.push
						href: href
						https: https
					Ajax.put '/user/link/add', link:
						name: href
						url: href
						https: https
					return
				else
					'<a href=' + JSON.stringify('http://' + href) + '>' + href + '</a>'

		scanAllLinks = (text, transformToLinks = false) ->
			((' ' + text)
				.replace /(\s)www\./g, '$1http://www.'
				.replace /(\s)(https?:\/\/\S+)/g, (all, space, link) ->
					if transformToLinks
						space + scanLink link, false
					else
						scanLink link
						all
			).substr 1

		richText = (text) ->
			scanAllLinks smiliesService.filter(text), true

		setRecentStatus = (data) ->
			has = (key) ->
				data[key] and typeof data[key] is 'object' and data[key].length
			if has 'chat'
				chatService.all data.chat
			if has 'recentStatus'
				$scope.recentStatus = data.recentStatus.map (status) ->
					status.images
						.map (image) ->
							if location.protocol is 'https:' and image.src.indexOf('http:') is 0
								image.src = image.src.replace /^[a-z]+:\/\/^[\/]+\//g, '/'
						.sort (a, b) ->
							if a.src and b.src
								a = (idFromUrl a.src) || a._id
								b = (idFromUrl b.src) || b._id
								if a < b
									1
								else if a > b
									-1
								else
									0
							else
								0
					for key in ['images', 'links', 'videos']
						$.each status[key], ->
							@statusId = status._id
							@concernMe = status.concernMe
					status.content = richText status.content
					status
				refreshScope $scope
				if getCachedData 'commentsEnabled'
					statusIds = (status._id for status in $scope.recentStatus when ! status.comments)

					if statusIds.length
						delay 1, ->
							Ajax.bigGet 'user/comment',
								data:
									statusIds: statusIds
								success: (data) ->
									if data.commentList
										$scope.recentStatus.map (status) ->
											if data.commentList[status._id]
												status.comments = data.commentList[status._id]
											status
										refreshScope $scope
									return
							return

				if location.hash
					delay 25, ->
						id = location.hash.substr 1
						cursor = $('<div class="scroll-cursor"></div>').prependTo '[data-id="' + id + '"]'
						cursor[0].scrollIntoView()
						cursor.remove()
						return
			return

		videoHosts =
			'//www.dailymotion.com/embed/video/$1': [
				/^dai\.ly\/([a-z0-9_-]+)/i
				/^dailymotion\.com\/video\/([a-z0-9_-]+)/i
			]
			'//www.youtube.com/embed/$1': [
				/^youtu\.be\/([a-z0-9_-]+)/i
				/^youtube\.com\/watch\?v=([a-z0-9_-]+)/i
			]

		###
		@override window.refreshMediaAlbums
		###
		refreshMediaAlbums = ->
			getAlbumsFromServer (err, albums) ->
				unless err
					$scope.albums = albums
					refreshScope $scope
					if window.setMediaAlbums
						setMediaAlbums albums
				return
			return

		$scope.delete = (status, $event) ->
			s = textReplacements
			bootbox.confirm s("Êtes-vous sûr de vouloir supprimer ce statut et son contenu ?"), (ok) ->
				if ok
					$($event.target)
						.parents('ul.dropdown-menu:first').trigger 'click'
						.parents('.status-block:first').slideUp ->
							$(@).remove()
							return
					medias = {images:status.images, videos:status.videos, links:status.links}
					$('.points').trigger('updatePoints', [status, medias, false])
					Ajax.delete '/user/status/' + status._id, ->
						if status.images and status.images.length
							delay 600, refreshMediaAlbums
						return
				return
			return

		$scope.report = (status, $event) ->
			$($event.target)
				.parents('ul.dropdown-menu:first').trigger 'click'
			status.reported = true
			Ajax.get '/report/' + status._id
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
			loadNewIFrames()
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
			scanLink href
			link.href = ''

			return

		$scope.send = (status) ->
			scanAllLinks status.content || ''
			$('.points').trigger('updatePoints', [status, $scope.medias, true])
			Ajax.put '/user/status/add' + (if at then '/' + at else ''),
				data:
					status: status
					at: at
					medias: $scope.medias || null
				success: (data) ->
					setRecentStatus data
					refreshMediaAlbums()
			status.content = ""
			initMedias()

			return

		$scope.sendComment = (status) ->
			comment = status.newComment
			statusMedias = $.extend {}, $scope.medias
			scanAllLinks comment.content || ''
			commentMedias = $.extend {}, $scope.medias
			$scope.medias = $.extend {}, statusMedias
			Ajax.put '/user/comment/add',
				data:
					status: status
					comment: comment
					at: at
					medias: commentMedias || null
				success: (data) ->
					#TODO return comment to user and notify friends
			comment.content = ""
			return

		$scope.loadMedia = (type, media) ->
			loadMedia type, media

			return

		at = getCachedData 'at'

		$scope.$on 'receiveStatus', (e, status) ->
			$scope.recentStatus.unshift status
			refreshScope $scope
			if status.images and status.author and status.images.length and status.author.hashedId is at
				refreshMediaAlbums()
			return

		window.statusScope = $scope

		$scope.status = containsMedias: false
		$scope.media = step: null

		select = if window.sessionStorage and sessionStorage.chats
			'recent'
		else
			'and/chat'

		Ajax.get '/user/status/' + select + (if at then '/' + at else ''), setRecentStatus

		getAlbums (err, albums) ->
			unless err
				$scope.albums = albums
				refreshScope $scope
			return

		initMedias()

		return

	Welcome: ($scope) ->
		delete sessionStorage['user']
		$('iframe.player').removeClass('hidden')
		$(window).trigger('resize')

		return
