Controllers =

	Album: ($scope) ->

		$scope.update = (album) ->

			Ajax.post 'user/album/' + album.id,
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
		return

	App: ($scope) ->

		opened = {}


		angular.extend $scope,

			app: {}

			open: (id) ->
				opened[id] = 1
				return

			close: (id) ->
				delete opened[id]
				return

			opened: (id) ->
				opened[id] is 1

			edited: (id) ->
				opened[id] is 2

			edit: (app) ->
				for id, state of opened
					opened[id] = 1
				@app = app
				opened[app.publicKey] = 2
				return

			delete: (appId, $event) ->

				s = textReplacements
				bootbox.confirm s("Êtes-vous sûr de vouloir supprimer cette application ?"), (ok) ->
					if ok
						$($event.target)
							.parents('ul.dropdown-menu:first').trigger 'click'
							.parents('.app:first').slideUp ->
								$(@).remove()
								return
						Ajax.delete '/user/app/' + appId, ->
							return
					return
				return
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
			me = getCachedData 'me'
			users = users.filter (user) ->
				user.hashedId isnt me
			ids = (user.hashedId for user in users)
			id = ids.join ','
			unless id
				return
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
				if currentChat.messages and currentChat.messages.length > 0
					for chatMessage in currentChat.messages by -1
						if chatMessage.from and (user = chatMessage.from).hashedId is message.from.hashedId and user.thumb50 isnt message.from.thumb50
							$img = $('img[data-user-thumb="' + user.hashedId + '"]:first').thumbSrc(message.from.thumb50.replace('50x', ''))
							if exists $img
								src = $img.prop('src').replace /\/photo\/[0-9]+x/g, '/photo/'
								for size in getCachedData 'thumbSizes'
									user['thumb' + size] = src.replace '/photo/', '/photo/' + size + 'x'
								for mess in currentChat.messages
									if mess.from
										if mess.from.hashedId is message.from.hashedId
											for size in getCachedData 'thumbSizes'
												mess.from['thumb' + size] = src.replace '/photo/', '/photo/' + size + 'x'
									if mess.users
										for aUser in mess.users
											if aUser.hashedId is message.from.hashedId
												for size in getCachedData 'thumbSizes'
													aUser['thumb' + size] = src.replace '/photo/', '/photo/' + size + 'x'
							break
				if message.from.hashedId is me
					delete message.from
				currentChat.messages.push message
				modified = true
			if modified
				saveChatState currentChat
				saveChats chats
				goToBottom = false
				if message and message.from
					messagesDiv = $('.chat[data-chat-id="' + message.from.hashedId + '"] .messages')[0]
					scrollHeight = messagesDiv.scrollHeight
					scrollTop = $(messagesDiv).scrollTop()
					height = $(messagesDiv).height()
					#we go to bottom of chat if we are already at the bottom before chat update
					#there is a gap of 5 px because of some difference between browsers on scrollTop() result
					if (scrollHeight - height - 5) < scrollTop
						goToBottom = true
			refreshScope $scope
			#force scroll at bottom
			if goToBottom
				newScrollHeight = $('.chat[data-chat-id="' + message.from.hashedId + '"] .messages')[0].scrollHeight
				$('.chat[data-chat-id="' + message.from.hashedId + '"] .messages:first').scrollTop(newScrollHeight)
			if !message
				delay 1, ->
					$('.chat[data-chat-id="' + id + '"] textarea:first').focus()

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

		$scope.$on 'clear', (e, users) ->
			chats = getChats()
			for id, chat of chats
				chatUserIds = []
				for userChat in chat.users
					chatUserIds.push userChat.hashedId
				if JSON.stringify(chatUserIds) is JSON.stringify(users)
					chat.messages = []
			$scope.chats = saveChats chats
			refreshScope $scope
			return

		$scope.$on 'updateNewMessages', (e, userIds, nbOfNewMessages) ->
			chats = getChats()
			for id, chat of chats
				chatUserIds = []
				for userChat in chat.users
					chatUserIds.push userChat.hashedId
				if JSON.stringify(chatUserIds) is JSON.stringify(userIds)
					chat.newMessages = nbOfNewMessages
					if nbOfNewMessages is 0
						chat.resetNewMessages = true

			$scope.chats = saveChats chats
			refreshScope $scope
			return

		$scope.$on 'changePageTitle', (e, newChatMessages) ->
			index = 0
			nbMessages = 0
			s = textReplacements
			for key, obj of newChatMessages
				index++
				name = obj.name
				nbMessages += obj.nbMessages

			$('title').html if index > 1
			    s("{count} nouveaux messages", count: nbMessages)
			else
			    '(' + nbMessages + ') ' + name

		$scope.close = (chat) ->
			chat.open = false
			saveChatState chat
			saveChats chats
			return

		$scope.send = (message, id) ->
			if message.content and message.content.length
				content = richText $scope, message.content, true
				chatData =
					date: new Date
					content: content
				postData =
					action: 'message'
					content: content
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

	ChatList: ($scope) ->

		$scope.chatWith = (user, $event) ->
			chatService.chatWith [objectResolve user]
			$($event.target).parents('.modal-content').find('button[data-dismiss]:first').trigger 'click'
			return

		$scope.mask = (user) ->
			s = textReplacements
			bootbox.confirm s("Êtes-vous sûr de vouloir supprimer l'intégralité de cette conversation ?"), (ok) ->
				if ok
					Ajax.delete '/user/chat/',
						data:
							otherUser: user.hashedId
						success: (data) ->
							chatService.clear [user.hashedId]
							newChatList = []
							for chat in $scope.chatList
								if chat.otherUser.hashedId isnt user.hashedId
									newChatList.push chat
							$scope.chatList = newChatList
							refreshScope $scope
							$('.user-chat[data-id="' + user.hashedId + '"]').slideUp ->
								$(@).remove()
								return
			return

		window.chatListScope = $scope

		return

	Contact: ($scope) ->
		$scope.contact = {}
		$scope.send = ->
			if $scope.contact.motif and $scope.contact.message
				$('#contact-error').hide()
				$('#contact-error').html ''
				Ajax.put '/contact',
					data:
						motif: $scope.contact.motif
						message: $scope.contact.message
					success: ->
						$('#contact [data-dismiss="modal"]:first').click()
						$scope.contact = {}

			else
				s= textReplacements
				$('#contact-error').html s('Le motif et le message sont obligatoires')
				$('#contact-error').show()
			return

		return

	Event: ($scope, $http) ->

		loadTemplate = ->
			$scope.template = template (if window.isMobile()
				'/mobile'
			else
				''
			) + '/event'
			refreshScope $scope

		$http.get('/event/123')
			.then (data) ->
				$scope.event = data.data.event
				refreshScope $scope

		onResize loadTemplate

	Head: ($scope) ->
		$scope.$on 'enableSmilies', (e, enabled) ->
			$scope.smilies = enabled

	LoginAndSignin: ($scope) ->
		keepTipedModel $scope, '#login-signin', 'user'
		saveUser $scope
		# Get remember preference of the user if previously saved (default: true)
		$scope.user.remember = (if hasLocalItem('user.remember') then !! getLocalValue('user.remember') else true)
		# When the form is submitted
		$scope.submitLogin = (user) ->
			@submit user
			# Save remember preference of the user
			setLocalValue 'user.remember', user.remember
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

		$scope.submitSignin = (formId, user) ->
			@submit user
			$('#'+formId)
				.attr "action" , "/user/signin"
				.attr "method" , "POST"
				.unbind 'submit'
			if $('input[name="_method"]').length
				$('input[name="_method"]').val "PUT"
			else
				$('#'+formId).append "<input type=hidden name='_method' value='PUT'>"

			keepTipedModel $scope, '#login-signin', 'user'
			saveUser $scope
			$('#'+formId).submit()
			return

		$('#login-signin').on 'submit', prevent

		return

	Medias: ($scope) ->
		$scope.selectAlbum = (album) ->
			locationHref '/user/album/' + album._id
			return

		window.setMediaAlbums = (albums) ->
			$scope.albums = albums
			refreshScope $scope
			$('#add-profile-photo')[if checkProfileAlbum() then 'show' else 'hide']()
			return

		window.refreshMediaAlbums = ->
			getAlbumsFromServer (err, albums) ->
				unless err
					setMediaAlbums albums
				return
			return

		if $('#all-albums').length
			at = getCachedData 'at'
			if !at
				at = getCachedData 'me'
			Ajax.get '/user/albums/all/' + at, (data) ->
				$scope.nbNonEmptyAlbums = data.nbAlbums || 0
				albums = removeDeprecatedAlbums data.albums
				unless data.err
					setMediaAlbums albums
				return
		else
			getAlbums (err, albums, nbAlbums, user) ->
				$scope.nbNonEmptyAlbums = nbAlbums || 0
				$scope.mediaUser = user
				unless err
					setMediaAlbums albums
				return

		$scope.nbAlbum = ->
			if $scope.albums
				s = textReplacements
				s('({nbAlbum} album)|({nbAlbum} albums)', nbAlbum: $scope.nbNonEmptyAlbums, $scope.nbNonEmptyAlbums).toUpperCase()

		$scope.nbPhotos = (album) ->
			if album
				s = textReplacements
				s('({nbPhoto} photo)|({nbPhoto} photos)', {nbPhoto: album.nbPhotos}, album.nbPhotos)

		$scope.loadMedia = (type, media) ->
			loadMedia type, media
			return

		checkProfileAlbum = () ->
			if $scope.mediaUser and $scope.mediaUser.photoAlbumId and $scope.albums
				albumIds = $scope.albums.map (obj) ->
					obj._id
				if $scope.mediaUser.photoAlbumId in albumIds
					false
				else
					true
			else
				true

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
									delay 600, window.refreshMediaAlbums
								else
									location.reload()
								hideLoader()
							error: ->
								serverError()
								hideLoader()
					return
			return

		$scope.videoHref = ->
			(($scope.loadedMedia || {}).href || '').replace '.youtube.com/', '.youtube-nocookie.com/'

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

		s = textReplacements
		$scope.photoDefaultName = s("Photos de profil")

		$scope.setAsProfilePhoto = ->
			s = textReplacements
			infoDialog s("Changement de ta photo de profil"), s("Cette photo remplacera l'actuelle photo de profil !"), "Confirmer", "Annuler", (ok) ->
				if ok
					$('#media-viewer [data-dismiss]:first').click()
					Ajax.post '/user/profile/photo',
						data: photoId: $scope.loadedMedia.id
						success: (res) ->
							if $('#profile-photo') and res and res.src
								$('#profile-photo img').thumbSrc res.src
							window.refreshMediaAlbums()
							return
			return


		window.loadMedia = (type, media, concernMe) ->
			$scope.loadMedia type, media, concernMe
			delay 1, ->
				$('#media-viewer').modal()
				return
			return

		return

	Notifications: ($scope, notificationsService, $sce) ->
		$scope.notifications = {}

		ids = $('.notifications li[data-id]').map ->
			$(@).data 'id'

		$scope.ifId = (id, defaultValue) ->
			if /^[0-9a-fA-F]+$/g.test id
				id
			else
				defaultValue

		$scope.trust = (html) ->
			$sce.trustAsHtml html

		$scope.$on 'receiveNotification', (e, notification) ->
			id = notification.id || notification[0]
			$('.no-notice').parent().hide()
			unless $scope.notifications[id] or id in ids
				$scope.notifications[id] = notification
				refreshScope $scope
				delay 1, refreshPill
			return

		$scope.$on 'setNotifications', (e, notifications) ->
			$scope.notifications = notifications.filter (notification) ->
				! notification[0] in ids
			refreshScope $scope
			delay 1, refreshPill
			return

		$scope.readAll = ->
			liUnread = $('.notification-list, .notification-list-mobile').find('li').not('.read, .activities-list, .read-all, .divider')
			if liUnread.length
				Ajax.post '/user/notify/read/all',
					data: {}
					success: ->
						return

				liUnread.addClass('read')
				refreshPill()

			return
		return

	NotificationList: ($scope, $sce) ->
		$scope.notificationList = []
		lastNoticeLoadedCount = null

		$scope.getLoadUrl = ->
			'/user/notify/list/' + $scope.getNoticeOffset()

		$scope.noticeRemaining = ->
			($scope.notificationList || []).length > 0 and lastNoticeLoadedCount > 0 and lastNoticeLoadedCount <= getCachedData 'noticePageCount'

		$scope.getNoticeOffset = ->
			notificationList = $scope.notificationList || []
			if notificationList.length
				notificationList[notificationList.length - 1]._id
			else
				0

		$scope.setRecentNotice = (data) ->
			lastNoticeLoadedCount = data.notices.length
			for notice in data.notices
				notice.content = $sce.trustAsHtml notice.content
			$scope.notificationList = $scope.notificationList.concat data.notices
			refreshScope $scope
			return

		Ajax.post '/user/notify/list/' + $scope.getNoticeOffset(),
			data: {}
			success: (data) ->
				$scope.setRecentNotice data
		return

	PlusWList: ($scope) ->
		$scope.likers = {}
		window.plusWListScope = $scope
		$scope.lastlikersLoadedCount = null

		$scope.getLoadUrl = ->
			'/user/plusW/list'

		$scope.likersRemaining = ->
			($scope.likers || []).length > 0 and $scope.lastlikersLoadedCount > 0 and $scope.lastlikersLoadedCount <= getCachedData 'likersPageCount'

		$scope.getlikersOffset = ->
			likersList = $scope.likers || []
			if likersList.length
				likersList[likersList.length - 1].plusWId
			else
				null

		$scope.loadlikersList = (chunk) ->
			$scope.lastlikersLoadedCount = chunk.likers.length
			for liker in chunk.likers
				$scope.likers.push liker
			refreshScope $scope

		$scope.getAdditionnalData = ->
			status: $scope.status
		return

	Profile: ($scope, chatService) ->
		$scope.chatWith = (user) ->
			chatService.chatWith [objectResolve user]
			return

		$scope.deleteFriend = (id, fullName) ->
			s = textReplacements
			infoDialog s("Confirmation"), s("Êtes-vous sûr de vouloir supprimer {fullName} de votre liste d'amis ?", fullName: fullName), (ok) ->
				if ok
					Ajax.delete '/user/friend',
						data: id: id
						success: ->
							location.reload()
			return

		$scope.deletePhoto = ($event) ->
			Ajax.delete '/user/photo', ->
				window.refreshMediaAlbums()
			$ $event.target
				.parents '[ng-controller]:first'
				.find '.upload-thumb'
				.prop 'src', '/img/default-photo.jpg'
			return

		loadNewIFrames()
		$scope.supportAudio = typeof Audio is "function" and (new Audio).canPlayType and (new Audio).canPlayType('audio/mp3').replace(/no/, '')

		audios = {}

		$scope.selectChatSound = (event, idSound) ->
			cancel event
			$scope.selectedSound = idSound
			refreshScope $scope

			$('[data-name="chatSound"]').data('value', idSound)

			if idSound
				if !audios[idSound]
					audios[idSound] = new Audio(mp3 'chatSound_'+idSound)
				audios[idSound].play()

			Ajax.post 'user/chat/sound',
				data: chatSound: idSound
				success: (res) ->
					return
			return

		return

	Search: ($scope) ->

		askedForFriends = []

		$scope.askForFriend = (user) ->
			askedForFriends.push user.hashedId
			return

		$scope.canBeAddedAsAFriend = (user) ->
			! user.isAFriend and ! user.askedForFriend and ! (user.hashedId in askedForFriends)

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

		search = null

		$scope.change = (query) ->
			if ajaxRequest
				ajaxRequest.abort()
			if search
				clearTimeout search
			keyWords = query.content
			if keyWords.length > 0
				search = delay 2000, ->
					trackEvent 'Search', 'Fail', keyWords
				query.action = '/user/first/' + keyWords
				ajaxRequest = Ajax.get '/user/search/' + encodeURIComponent keyWords
				.done (data) ->
					if data.users
						clearTimeout search
						trackEvent 'Search', (if data.users.length then 'Results' else 'No results'), keyWords
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

	SigninSecondStep: ($scope) ->
		user = getSessionValue 'user'
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

		#hack for enable scroll on legals modal
		$('.modal').on 'shown.bs.modal', ->
			$('body')
				.height '9999px'
				.height ''

		return

	Status: ($scope, smiliesService, statusService, paginate) ->

		initMedias = ->
			$scope.medias =
				links: []
				images: []
				videos: []
			return

		$scope.displayPlayer = ! navigator.standalone

		$scope.thumbnail = (url) ->
			url
				.replace /\/\/www\.youtube\.com\/embed\/([a-z0-9_-]+)/ig, '//img.youtube.com/vi/$1/0.jpg'
				.replace /\/\/www\.dailymotion\.com\/embed\/video\/([a-z0-9_-]+)/ig, '//www.dailymotion.com/thumbnail/video/$1'

		$scope.removeMedia = (media) ->
			Ajax.delete '/user/media/preview',
				data: media
				success: (data)->
					if data.id
						for type in ["image", "video", "link"]
							if data.type is type
								key = type + 's'
								for media, index in $scope.medias[key]
									if media and media.id is data.id
										$scope.medias[key].splice index, 1
								break
						$('.tab .medias img[src="' + data.src + '"]').parent().remove()
					else
						location.reload()
					hideLoader()
				error: ->
					serverError()
					hideLoader()

		lastStatusLoadedCount = null
		$scope.nbCommentLoaded = false

		$scope.loadStatusList = setRecentStatus = (data, toPush = true) ->
			has = (key) ->
				data[key] and typeof data[key] is 'object' and data[key].length
			if has 'chat'
				chatService.all data.chat
			if has 'recentStatus'
				$scope.recentStatus ||= []
				recentStatusIds = $scope.recentStatus.map (status) ->
					status._id
				chunk = data.recentStatus.map (status) ->
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
					status.content = richText $scope, status.content
					status.isMine = isMe(status.author.hashedId)
					status.nbLike ||= 0
					status
				for status in chunk
					index = recentStatusIds.indexOf status._id
					if ~index
						$scope.recentStatus[index] = status
					else
						if toPush
							$scope.recentStatus.push status
						else
							$scope.recentStatus.uniqueUnshift status
				lastStatusLoadedCount = chunk.length
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
												status.nbComment = data.commentList[status._id].length
											else
												status.nbComment = 0
											status
										$scope.nbCommentLoaded = true
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
			else
				lastStatusLoadedCount = 0
			return

		###
		@override window.refreshMediaAlbums
		###
		refreshMediaAlbums = ->
			Ajax.get 'user/albums', (data) ->
				err = data.err || null
				if data.albums
					albums = removeDeprecatedAlbums( data.withAlbums || data.albums )
					$scope.albums = albums
					refreshScope $scope
					if window.refreshMediaAlbums
						window.refreshMediaAlbums()
			return

		$scope.delete = (status, $event) ->
			s = textReplacements
			infoDialog s("Suppression"), s("Êtes-vous sûr de vouloir supprimer ce statut et son contenu ?"), (ok) ->
				if ok
					$($event.target)
						.parents('ul.dropdown-menu:first').trigger 'click'
						.parents('.status-block:first').slideUp ->
							$(@).remove()
							return
					$('.points').trigger 'updatePoints', [status, false]
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
			removeSessionItem albumKey()
			Ajax.put '/user/album/add',
				data:
					album: album
			$scope.selectAlbum album
			album =
				name: ''
				description: ''
			return

		$scope.addMedia = (link) ->
			href = link.href
			match = href.match /src="([^"]+)"/g
			if match and match.length > 1
				href = match[1]
			scanLink $scope, href
			link.href = ''

			return

		$scope.send = (status) ->
			scanAllLinks $scope, status.content || ''

			Ajax.put '/user/status/add' + getLastestUpdateChatId() + (if at then '/' + at else ''),
				data:
					status: status
					at: at
					medias: $scope.medias || null
				success: (data) ->
					$('.points').trigger 'updatePoints', [data.newStatus, true]
					setRecentStatus data, false
					refreshMediaAlbums()
			status.content = ""
			initMedias()

			return

		updateCommentList = (data) ->
			if data.commentList
				for status in $scope.recentStatus
					if data.commentList[status._id]
						status.comments = data.commentList[status._id]
						status.nbComment = data.commentList[status._id].length
						refreshScope $scope
						break

		$scope.sendComment = (status) ->
			if status.newComment
				comment = status.newComment
				statusMedias = $.extend {}, $scope.medias
				scanAllLinks $scope, comment.content || ''
				commentMedias = $.extend {}, $scope.medias
				$scope.medias = $.extend {}, statusMedias
				Ajax.put '/user/comment/add',
					data:
						status: status
						comment: comment
						at: at
						medias: commentMedias || null
					success: updateCommentList
				comment.content = ""
			return

		$scope.deleteComment = (comment) ->
			s = textReplacements
			infoDialog s("Suppression"), s("Êtes-vous sûr de vouloir supprimer ce commentaire ?"), (ok) ->
				if ok
					Ajax.delete '/user/comment',
						data:
							comment: comment

					$('.comment-block[data-data="' + comment._id + '"]').slideUp ->
						$(@).remove()
						return
				return
			return

		$scope.updateComment = (comment) ->
			Ajax.post '/user/comment',
				data:
					comment: comment
				success: updateCommentList
			return

		$scope.updateStatus = (status) ->
			#We have to do this before post because it also put videos in status.videos
			contentToDisplay = richText $scope, status.content, false, false, status
			Ajax.post '/user/status',
				data:
					status: status
			status.content = contentToDisplay
			refreshScope $scope
			return

		$scope.loadMedia = (type, media) ->
			loadMedia type, media
			$('#media-viewer').one 'shown.bs.modal', ->
				$('iframe[data-ratio]').ratio()
				return
			return

		$scope.toggleLike = (status, adding) ->
			$('[data-id="'+status._id+'"] .btn-action-plus-w').attr 'disabled', true
			if arguments.length < 2
				adding = ! status.likedByMe
			status.likedByMe = adding
			status.nbLike += if adding
				1
			else
				-1
			status.nbLike = 0 if status.nbLike < 0
			refreshScope $scope
			SingleAjax[if adding then 'put' else 'delete'] 'plusw' + status._id, '/user/plusw',
				data:
					status: status
					at: at
				success: (result) ->
					$('[data-id="'+status._id+'"] .btn-action-plus-w').removeAttr 'disabled'
					true


		$scope.nbLikeText = (status) ->
			s = textReplacements
			s("{nbLike} personne aime ça.|{nbLike} personnes aiment ça.", { nbLike: status.nbLike }, status.nbLike)

		$scope.nbCommentText = (status) ->
			s = textReplacements
			s("{nbComm} commentaire|{nbComm} commentaires", { nbComm: status.nbComment }, status.nbComment)

		at = getCachedData 'at'

		$scope.$on 'receiveStatus', (e, status) ->
			status.content = richText $scope, status.content
			$scope.recentStatus.uniqueUnshift '_id', status
			refreshScope $scope
			if status.images and status.author and status.images.length and status.author.hashedId is at
				refreshMediaAlbums()
			return

		$scope.$on 'receiveComment', (e, comment) ->
			for status in $scope.recentStatus
				if comment.attachedStatus and status._id is comment.attachedStatus
					comment.isMine = comment.author.hashedId is getData 'me'
					statusAt = status.at || status.author
					comment.onMyWall = statusAt.hashedId is getData 'me'
					(status.comments ||= []).uniquePush '_id', comment
					break
			refreshScope $scope
			return

		window.statusScope = $scope

		$scope.status = containsMedias: false
		$scope.media = step: null

		select = if getSessionItem 'chats'
			'recent'
		else
			'and/chat' + getLastestUpdateChatId()

		$scope.getLoadUrl = ->
			'/user/status/' + select + (if at then '/' + at else '')

		$scope.statusRemaining = ->
			($scope.recentStatus || []).length > 0 and lastStatusLoadedCount > 0 and lastStatusLoadedCount <= getCachedData 'statusPageCount'

		$scope.getStatusOffset = ->
			statusList = $scope.recentStatus || []
			if statusList.length
				statusList[statusList.length - 1]._id
			else
				null

		$scope.showCommentBlock = (status) ->
			delay 1, ->
				status.commentForm = true
				status.commentList = true
				refreshScope statusScope
				return
			return

		unlink = (text) ->
			(((' ' + text)
				.replace /(<a\s)(.*?)(href=\")(.*?)(\">)(.*?)(<\/a>)/gi, (match, p1, p2, p3, p4, p5, p6, p7, offset, string) ->
					p4 + ' '
			).substr 1)

		$scope.toggleStatusState = (status, edit) ->
			status.edit = edit
			status.content = if edit
				unlink smiliesService.unfilter status.content
			else
				status.originalContent
			refreshScope $scope
			return

		lock = false
		$scope.displaylikerList = (status) ->
			if !window.isMobile() and !lock and status.nbLike
				lock = true
				Ajax.post '/user/plusW/list',
					data: status: status
					success: (data) ->
						window.plusWListScope.lastlikersLoadedCount = data.likers.length
						window.plusWListScope.likers = data.likers
						window.plusWListScope.status = status
						refreshScope window.plusWListScope
						$('#liker-list').modal 'show'
						lock = false
						return
			return

		Ajax.post $scope.getLoadUrl(),
			data: {}
			success: (data) ->
				setRecentStatus data

		refreshMediaAlbums()

		initMedias()

		return

	Welcome: ($scope) ->
		removeSessionItem 'user'
		$('iframe.player').removeClass('hidden')
		$(window).trigger('resize')

		return
