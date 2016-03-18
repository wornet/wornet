Controllers =

	AdminCertification: ($scope) ->
		$scope.removeCertification = (certifId) ->
			Ajax.get '/admin/certification/remove/' + certifId, ->
				$('.certification-table tr[data-certif-id="' + certifId + '"]').slideUp ->
					$(@).remove()
					return

		$scope.acceptCertification = (certifId) ->
			Ajax.get '/admin/certification/accept/' + certifId, (result) ->
				if result.err
					serverError result.err.msg
				$('.certification-table tr[data-certif-id="' + certifId + '"]').slideUp ->
					$(@).remove()
					return


		$scope.certification = {}
		$scope.loadCertif = (certifId) ->
			if $scope.certificationPending
				for certif in $scope.certificationPending
					if certif._id == certifId
						$('.user-type').val(certif.userType).prop 'disabled', true
						toggleForm()
						$('.firstName').val(certif.userFirstName).prop 'disabled', true
						$('.lastName').val(certif.userLastName).prop 'disabled', true
						$('.telNumber').val(certif.userTelephone).prop 'disabled', true
						$('.email').val(certif.userEmail).prop 'disabled', true
						$('.businessName').val(certif.businessName).prop 'disabled', true
						$('.message').val(certif.message).prop 'disabled', true
						$('.proof').remove()
						$('.proof-visu')
							.prop 'href', certif.proof.src
							.html certif.proof.name
							.show()
						$('.modal-footer .btn').hide()
						$('#certification').modal()
						return

		toggleForm = ->
			if $("select.user-type").val() is "particular"
				$(".entreprise").hide()
				$(".particulier").show()
			else
				$(".entreprise").show()
				$(".particulier").hide()
				if $("select.user-type").val() is "business"
					$(".entreprise-only").show()
					$(".association-only").hide()
				else
					$(".entreprise-only").hide()
					$(".association-only").show()
			return

		return
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

	Certification: ($scope) ->
		s = textReplacements
		$scope.send = ->
			$('#certification-form').submit()
			return

		$scope.toggleForm = ->
			if $("select.user-type").val() is "particular"
				$(".entreprise").hide()
				$(".particulier").show()
			else
				$(".entreprise").show()
				$(".particulier").hide()
				if $("select.user-type").val() is "business"
					$(".entreprise-only").show()
					$(".association-only").hide()
				else
					$(".entreprise-only").hide()
					$(".association-only").show()
			return


		$scope.certification = {}
		$scope.initModal = ->
			$scope.certification.userType = "particular"
			$scope.certification.name = {}
			$scope.certification.firstName = $('input[name="name.first"]:last').val()
			$scope.certification.lastName = $('input[name="name.last"]:last').val()
			$scope.certification.email = $('input[name="email"]:last').val()
			refreshScope $scope
			return

		$scope.initModal()
		$scope.toggleForm()

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
					alreadyInChat = false
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
						if chatMessage.date and message.date and Math.floor(chatMessage.date.getTime() / 1000) is Math.floor(message.date.getTime() / 1000) and chatMessage.content is message.content
							alreadyInChat = true
				if message.from.hashedId is me
					delete message.from
				if !alreadyInChat
					currentChat.messages.push message
					modified = true
			if modified
				saveChatState currentChat
				saveChats chats
			refreshScope $scope
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
				content = richText $scope, message.content, true, true
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
			infoDialog s("Suppression de conversation"), s("Êtes-vous sûr de vouloir supprimer l'intégralité de cette conversation ?"), (ok) ->
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
		s = textReplacements
		$scope.send = ->
			if $scope.contact.motif and $scope.contact.message
				$('#contact-error').hide()
				$('#contact-error').html ''
				Ajax.put '/contact',
					data:
						motif: $scope.contact.motif
						message: $scope.contact.message
					success: ->
						toastr.success s("Votre message a bien été envoyé. Merci !"), s "C'est fait"
						$('#contact [data-dismiss="modal"]:first').click()
						$scope.contact = {}

			else
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

		$http.get('move/event/123')
			.then (data) ->
				$scope.event = data.data.event
				refreshScope $scope

		onResize loadTemplate

	EventForm: ($scope) ->
		$.extend $scope,
			etape: 1
			event:
				author: {}
			send: (event) ->
				settings = data: event: $scope.event
				Ajax.put '/api/move/add', settings, (data) ->
					return
				cancel event
				return
		return


	FollowerList: ($scope) ->
		$scope.followers = {}
		window.followerListScope = $scope
		$scope.lastfollowerLoadedCount = null

		$scope.getLoadUrl = ->
			'/user/follower/list'

		$scope.followerRemaining = ->
			($scope.followers || []).length > 0 and $scope.lastfollowerLoadedCount > 0 and $scope.lastfollowerLoadedCount <= getCachedData 'followersPageCount'

		$scope.getfollowersOffset = ->
			followersList = $scope.followers || []
			if followersList.length
				followersList[followersList.length - 1].hashedId
			else
				null

		$scope.loadfollowersList = (chunk) ->
			$scope.lastfollowerLoadedCount = chunk.followers.length
			for follower in chunk.followers
				$scope.followers.push follower
			refreshScope $scope

		$scope.getAdditionnalData = (hashedId) ->
			userHashedId: hashedId

		$scope.displayFollowerList = window.displayFollowerList

		return

	FollowingList: ($scope) ->
		$scope.followings = {}
		window.followingListScope = $scope
		$scope.lastfollowingLoadedCount = null

		$scope.getLoadUrl = ->
			'/user/following/list'

		$scope.followingRemaining = ->
			($scope.followings || []).length > 0 and $scope.lastfollowingLoadedCount > 0 and $scope.lastfollowingLoadedCount <= getCachedData 'followingsPageCount'

		$scope.getfollowingsOffset = ->
			followingsList = $scope.followings || []
			if followingsList.length
				followingsList[followingsList.length - 1].hashedId
			else
				null

		$scope.loadfollowingsList = (chunk) ->
			$scope.lastfollowingLoadedCount = chunk.followings.length
			for following in chunk.followings
				$scope.followings.push following
			refreshScope $scope

		$scope.getAdditionnalData = (hashedId) ->
			userHashedId: hashedId

		$scope.displayFollowingList = window.displayFollowingList

		return

	FriendList: ($scope) ->
		$scope.friends = {}
		window.friendListScope = $scope
		$scope.lastfriendLoadedCount = null

		$scope.getLoadUrl = ->
			'/user/friend/list'

		$scope.friendRemaining = ->
			($scope.friends || []).length > 0 and $scope.lastfriendLoadedCount > 0 and $scope.lastfriendLoadedCount <= getCachedData 'friendsPageCount'

		$scope.getfriendsOffset = ->
			friendsList = $scope.friends || []
			if friendsList.length
				friendsList[friendsList.length - 1].idFriend
			else
				null

		$scope.loadfriendsList = (chunk) ->
			$scope.lastfriendLoadedCount = chunk.friends.length
			for friend in chunk.friends
				$scope.friends.push friend
			refreshScope $scope

		$scope.getAdditionnalData = (hashedId) ->
			userHashedId: hashedId

		$scope.displayFriendList = window.displayFriendList

		return

	Head: ($scope) ->
		$scope.$on 'enableSmilies', (e, enabled) ->
			$scope.smilies = enabled

		if window.isMobile() and $('#shutter').css("width") isnt "0px"
			$('.wornet-navbar, #wrap, #shutter').removeClass 'opened-shutter'
			$('#directives-calendar > .well').removeClass 'col-xs-9'
			Ajax.post '/user/shutter/' + (if $('#shutter').is '.opened-shutter' then 'open' else 'close')

	Invite: ($scope) ->
		s = textReplacements
		FACEBOOK_APP_ID = "400859870103849"
		FACEBOOK_POST_LINK = "https://www.wornet.fr"
		FACEBOOK_POST_LIST = [
			message: s("Salut les amis, je viens de rejoindre le réseau social éthique Wornet ! Rejoignez-moi sur www.wornet.fr :)")
		,
			message: s("Hello les amis, je me suis inscrit sur le réseau social éthique Wornet ! C'est plutôt sympathique rejoignez-moi sur www.wornet.fr :)")
		,
			message: s("Je viens de rejoindre le réseau social éthique Wornet (www.wornet.fr). Rejoignez-moi dessus :)")
		]

		FB.init
			appId: FACEBOOK_APP_ID
			xfbml: true
			version: 'v2.4'

		$scope.inviteFacebook = ->
			post = FACEBOOK_POST_LIST[Math.floor Math.random() * FACEBOOK_POST_LIST.length]
			infoDialog s("Inviter vos amis"), "<p>Votre message Facebook : </p><textarea id='facebookPostMessage' placeholder='" + s('(Facultatif)') + "'></textarea><br><span class='facebookExemple'>" + s('Par exemple: ') + post.message + "</span>", (ok) ->
				if ok
					post.message = $('#facebookPostMessage').val()
					FB.login ->
						# Note: The call will only work if you accept the permission request
						post.link = FACEBOOK_POST_LINK
						FB.api '/me/feed', 'post', post
					, scope: 'publish_actions'
			return

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
			getAlbumsFromServer (err, albums, nbAlbums, user) ->
				$scope.nbNonEmptyAlbums = nbAlbums || 0
				$scope.mediaUser = user
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
			$children = $ '#media-viewer > * > * img.big'
			$children.fadeOut 100, ->
				action()
				delay 20, ->
					$children.fadeIn 100
					return
				return
			return

		$scope.prev = ->
			if $scope.mediaPrev and $scope.mediaPrev.src and $scope.mediaPrev.album
				$scope.inFade ->
					$('#media-viewer .img-buttons').hide()
					$scope.mediaNext = $scope.loadedMedia
					$scope.loadedMedia = $scope.mediaPrev
					refreshScope $scope
					resizeViewer()
					delay 200, ->
						testSize()

				delay 200, ->
					if prev = getPrev()
						$scope.loadMedia 'image', prev, "prev"
					else
						$scope.mediaPrev = null
					return

		$scope.next = ->
			if $scope.mediaNext and $scope.mediaNext.src and $scope.mediaNext.album
				$scope.inFade ->
					$('#media-viewer .img-buttons').hide()
					$scope.mediaPrev = $scope.loadedMedia
					$scope.loadedMedia = $scope.mediaNext
					refreshScope $scope
					resizeViewer()
					delay 200, ->
						testSize()

				delay 200, ->
					if next = getNext()
						$scope.loadMedia 'image', next, "next"
					else
						$scope.mediaNext = null
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

		resizeViewer = ->
			$mediaViewer = $ '#media-viewer'
			$img = $mediaViewer.find 'img.big'
			gap = 20

			if window.isMobile()
				newHeight = window.innerHeight
				newWidth = window.innerWidth
			else
				$rawImg = new Image
				$rawImg.src = $img.attr 'src'

				newHeight = Math.max(180, $rawImg.height + gap * 2)
				newWidth = Math.max(180, $rawImg.width + gap * 2)

			$mediaViewer.find('.modal-dialog')
				.height newHeight
				.width newWidth

			if window.isMobile()
				headerHeight = $mediaViewer.find('.modal-header').outerHeight()
				footerHeight = $mediaViewer.find('.modal-footer').outerHeight()
				bodyHeight = newHeight - (footerHeight + headerHeight) - 2 # 2 * border 1px
				$mediaViewer.find('.modal-body')
					.height bodyHeight
				imgMargin = (bodyHeight - $img.height()) / 2
				$img.css 'margin-top', imgMargin

		testSize = ->
			$mediaViewer = $ '#media-viewer'
			$img = $mediaViewer.find 'img.big'
			if $img.length
				$mediaViewer
					.find 'img.big, a.next, a.prev'
					.css 'max-height', Math.max(180, window.innerHeight - 180) + 'px'
				w = $img.width()
				h = $img.height()
				if w * h
					between = (min, max, number) ->
						Math.max min, Math.min max, Math.round number
					$mediaViewer.find('.img-buttons')
						.css 'margin-top', -h
						.width w
					$mediaViewer.find('.img-buttons').show()
					$mediaViewer.find('.img-buttons, .prev, .next').height h
					$mediaViewer.find('.prev, .next')
						.width Math.round w / 2
						.css 'line-height', (h + between 0, 20, h / 2 - 48) + 'px'
						.css 'font-size', between 16, 64, (Math.min w / 2, h / 2) - 10
				else
					delay 200, testSize
			return

		$scope.videoHref = ->
			(($scope.loadedMedia || {}).href || '').replace '.youtube.com/', '.youtube-nocookie.com/'

		$scope.mediaNext = {}
		$scope.mediaPrev = {}
		# loadedAlbum = null
		$scope.loadMedia = (type, media, concernMe, position = "middle") ->
			if "string" is typeof concernMe
				position = concernMe
				concernMe = null
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
			if id
				$.extend media,
					date: Date.fromId(id).toISOString()
					id: id

				treatReturn = (media, data) ->
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
					$.extend media, data

				Ajax.get '/user/photo/' + id, (data) ->
					treatReturn media, data
					if position is "middle"
						delay 100, ->
							if next = getNext()
								Ajax.get '/user/photo/' + idFromUrl(next.src), (dataNext) ->
									next.id = idFromUrl next.src
									next.date = Date.fromId(next.id).toISOString()
									next.type = "image"
									treatReturn next, dataNext
									$scope.mediaNext = next
									refreshScope $scope
									return
							if prev = getPrev()
								Ajax.get '/user/photo/' + idFromUrl(prev.src), (dataPrev) ->
									prev.id = idFromUrl prev.src
									prev.date = Date.fromId(prev.id).toISOString()
									prev.type = "image"
									treatReturn prev, dataPrev
									$scope.mediaPrev = prev
									refreshScope $scope
									return

						refreshScope $scope
						delay 10, ->
							resizeViewer()
							delay 200, ->
								testSize()
					return
			else
				delay 10, ->
					resizeViewer()
					delay 200, ->
						testSize()
			if position is "prev"
				$scope.mediaPrev = media
			else if position is "next"
				$scope.mediaNext = media
			else
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

		$scope.isMobile = window.isMobile()

		window.loadMedia = (type, media, concernMe) ->
			$scope.loadMedia type, media, concernMe
			delay 1, ->
				$('#media-viewer').modal()
				return
			return

		return

	MoveSearch: ($scope) ->

		$scope.popularTags = ['Rencontre', 'Soirées', 'Boite', 'Course', 'Bar', 'Jeune', 'Festival', 'Musique', 'Métal', 'Rock']

		$scope.createTag = (tag) ->
			$('#tag-list').tagit 'createTag', tag

		$('#tag-list').tagit
			caseSensitive: false

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
			else if id and /_count$/.test notification[2]
				$('.notifications li[data-id]').each (idElem, elem) ->
					$elem = $ elem
					if $elem.data('id') is id
						saveDate = $elem.find('i.mobile-notification-date, div.notification-date')
						$elem.find('a:first').html notification[1]
						$elem.removeClass 'read'
						delay 1, refreshPill
						saveDate.each (idElem, elem) ->
							$elem.find('a:first').append elem

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

		$scope.displayFollowerList = (hashedId, fromNotice) ->
			window.displayFollowerList(hashedId, fromNotice)
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

		$scope.follow = (hashedId, follow = true) ->
			if hashedId
				$('.follow').prop 'disabled', true
				$('.unfollow').prop 'disabled', true
				Ajax[if follow then "put" else "delete"] "user/profile/follow",
					data:
						hashedId: hashedId
					success: (res) ->
						$(if follow then '.follow' else '.unfollow').hide()
						$(if !follow then '.follow' else '.unfollow').show()
						$('.follow').prop 'disabled', false
						$('.unfollow').prop 'disabled', false
						if follow
							$('p.numberOfFollowers').html parseInt($('p.numberOfFollowers').html()) + 1
						else
							$('p.numberOfFollowers').html parseInt($('p.numberOfFollowers').html()) - 1

						for status in statusScope.recentStatus
							if status.at and status.at.hashedId is hashedId or status.author and status.author.hashedId is hashedId
								status.isPlaceFollowed = follow
						refreshScope statusScope
						return

		$scope.unfollow = (id) ->
			$scope.follow id, false

		lock = false
		window.displayFriendList = $scope.displayFriendList = (hashedId) ->
			if !lock and $scope.numberOfFriends
				lock = true
				Ajax.post '/user/friend/list',
					data: userHashedId: hashedId
					success: (data) ->
						window.friendListScope.lastfriendLoadedCount = data.friends.length
						window.friendListScope.friends = data.friends
						refreshScope window.friendListScope
						$('#friend-list').modal 'show'
						lock = false
						return
			return
		window.displayFollowerList = $scope.displayFollowerList = (hashedId, fromNotice = false) ->
			if !lock and ($scope.numberOfFollowers or fromNotice)
				lock = true
				Ajax.post '/user/follower/list',
					data: userHashedId: hashedId
					success: (data) ->
						window.followerListScope.lastfollowerLoadedCount = data.followers.length
						window.followerListScope.followers = data.followers
						refreshScope window.followerListScope
						$('#follower-list').modal 'show'
						lock = false
						return
			return
		window.displayFollowingList = $scope.displayFollowingList = (hashedId) ->
			if !lock and $scope.numberOfFollowing
				lock = true
				Ajax.post '/user/following/list',
					data: userHashedId: hashedId
					success: (data) ->
						window.followingListScope.lastfollowingLoadedCount = data.followings.length
						window.followingListScope.followings = data.followings
						refreshScope window.followingListScope
						$('#following-list').modal 'show'
						lock = false
						return
			return
		$scope.isMobile = window.isMobile()
		return

	Search: ($scope) ->

		askedForFriends = []

		$scope.askForFriend = (user) ->
			askedForFriends.push user.hashedId
			return

		$scope.canBeAddedAsAFriend = (user) ->
			! user.isAFriend and ! user.askedForFriend and ! (user.hashedId in askedForFriends) and user.accountConfidentiality == "private"

		$scope.canBeFollowed = (user) ->
			user.accountConfidentiality == "public" and ! user.isAFollowing and ! user.isAFriend

		$scope.canBeUnfollowed = (user) ->
			user.accountConfidentiality == "public" and user.isAFollowing and ! user.isAFriend

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

		$scope.firstSearch = false
		$scope.pendingSearch = false

		$scope.change = (query) ->
			$scope.query.users = []
			$scope.pendingSearch = true
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
					$scope.pendingSearch = false
					$scope.firstSearch = true
					if data.users
						clearTimeout search
						trackEvent 'Search', (if data.users.length then 'Results' else 'No results'), keyWords
						$scope.query.users = data.users
						refreshScope $scope
			else
				$scope.pendingSearch = false
				$scope.firstSearch = false
				$scope.query.users = []
				query.action = '#'
			return

		$scope.dismissResults = ->
			$('.suggests').hide()

		$scope.showResults = ->
			$('.suggests').show()

		if ~((window.navigator || {}).userAgent || '').indexOf('Safari/')
			delay 1, ->
				$('#search').hide()
				delay 1, ->
					$('#search').show()

		return

	Settings: ($scope) ->

		s = textReplacements
		urlPattern = "https://www.wornet.fr/"
		$scope.generateURLVisu = ->
			$('#urlVisual').html urlPattern + $('#uniqueURLID').val().toLowerCase()
			return

		validFormat = (id) ->
			/^[a-z0-9_.]*$/.test id

		$scope.checkURLID = ->
			urlId = $('#uniqueURLID').val().toLowerCase()
			if urlId and validFormat urlId
				Ajax.get '/user/checkURLID/' + urlId, (data) ->
					if data.err and data.err is "same"
						$('#urlIdDisponibility').html s("C'est vous !")
						$('#urlIdDisponibility').removeClass "red"
						$('#urlIdDisponibility').addClass "green"
					else if data.isAvailable
						$('#urlIdDisponibility').html s("Disponible !")
						$('#urlIdDisponibility').removeClass "red"
						$('#urlIdDisponibility').addClass "green"
					else
						$('#urlIdDisponibility').html s("Non disponible !")
						$('#urlIdDisponibility').removeClass "green"
						$('#urlIdDisponibility').addClass "red"
			else
				$('#urlIdDisponibility').html s("Caractères acceptés : lettres minuscules non accentuées, chiffres, points et undescores")
				$('#urlIdDisponibility').removeClass "green"
				$('#urlIdDisponibility').addClass "red"
			return

		$scope.generateURLVisu()

		$scope.showPasswordFields = ->
			$('.password-fields').show()
			$('.change-password-link').hide()
			return

		$scope.togglePasswordVisu = (inputName) ->
			inputType = $('input.form-control[name="' + inputName + '"]').attr 'type'
			$('input.form-control[name="' + inputName + '"]').attr 'type', if inputType is "password" then "text" else "password"
			$('a.toggle-password-view.' + inputName + ' span.glyphicons')[if inputType is "password" then "removeClass" else "addClass"] 'glyphicons-eye-open'
			$('a.toggle-password-view.' + inputName + ' span.glyphicons')[if inputType isnt "password" then "removeClass" else "addClass"] 'glyphicons-eye-close'
			return

		return

	ShareList: ($scope) ->
		$scope.sharers = {}
		window.shareListScope = $scope
		$scope.lastsharersLoadedCount = null

		$scope.getLoadUrl = ->
			'/user/share/list'

		$scope.sharersRemaining = ->
			($scope.sharers || []).length > 0 and $scope.lastsharersLoadedCount > 0 and $scope.lastsharersLoadedCount <= getCachedData 'sharersPageCount'

		$scope.getsharersOffset = ->
			sharersList = $scope.sharers || []
			if sharersList.length
				sharersList[sharersList.length - 1].id
			else
				null

		$scope.loadsharersList = (chunk) ->
			$scope.lastsharersLoadedCount = chunk.sharers.length
			for sharer in chunk.sharers
				$scope.sharers.push sharer
			refreshScope $scope

		$scope.getAdditionnalData = ->
			status: $scope.status
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

	Status: ($scope, smiliesService, statusService) ->
		s = textReplacements
		initMedias = ->
			$scope.medias =
				links: []
				images: []
				videos: []
			$scope.scannedLink = {}
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
						$('.status-form .status-images .image-box img[src="' + data.src + '"]').parent().remove()
					else
						location.reload()
					hideLoader()
				error: ->
					serverError()
					hideLoader()

		lastStatusLoadedCount = null

		$scope.loadStatusList = setRecentStatus = (data, toPush = true) ->
			has = (key) ->
				data[key] and typeof data[key] is 'object' and data[key].length
			if has 'chat'
				chatService.all data.chat
			if data.newStatus and has 'recentStatus'
				i = 0
				for recStatus in data.recentStatus
					if recStatus._id is data.newStatus._id
						data.recentStatus[i] = data.newStatus
						break
					i++
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
					status.isMine = if !status.isAShare
						isMe(status.author.hashedId)
					else
						false
					status.nbComment = 0
					status.nbLike ||= 0
					status
				for status in chunk
					index = recentStatusIds.indexOf status._id
					if ~index
						if $scope.recentStatus[index].nbComment
							status.nbComment = $scope.recentStatus[index].nbComment
						$scope.recentStatus[index] = status
					else
						if toPush
							$scope.recentStatus.push status
						else
							$scope.recentStatus.uniqueUnshift status
				lastStatusLoadedCount = chunk.length
				refreshScope $scope
				if getCachedData 'commentsEnabled'
					statusIds = []
					for status in $scope.recentStatus
						if ! status.comments
							statusIds.push if status.isAShare and status.referencedStatus
								status.referencedStatus
							else
								status._id
					if statusIds.length
						delay 1, ->
							Ajax.bigGet 'user/comment',
								data:
									statusIds: statusIds
								success: (data) ->
									if data.commentList
										$scope.recentStatus.map (status) ->
											idToTest = if status.isAShare
												status.referencedStatus
											else
												status._id
											if data.commentList[idToTest]
												for comment in data.commentList[idToTest]
													comment.content = richText $scope, comment.content, true, false
												status.comments = data.commentList[idToTest]
												status.nbComment = data.commentList[idToTest].length
											else
												#to prevent 0 on scroll
												if !status.nbComment
													status.nbComment = 0
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
					albums.sort (a, b) ->
						if a._id is getData 'photoUploadAlbumId'
							-1
						else
							1
					$scope.albums = albums
					refreshScope $scope
					if window.refreshMediaAlbums
						window.refreshMediaAlbums()
			return

		$scope.delete = (status, $event) ->
			infoDialog s("Suppression"), s("Êtes-vous sûr de vouloir supprimer ce statut et son contenu ?"), (ok) ->
				if ok
					if !$scope.monoStatut
						$($event.target)
							.parents('ul.dropdown-menu:first').trigger 'click'
							.parents('.status-block:first').slideUp ->
								$(@).remove()
								return
					$('.points').trigger 'updatePoints', [status, false]
					Ajax.delete '/user/status/' + status._id, ->
						if status.images and status.images.length
							delay 600, refreshMediaAlbums
						if $scope.monoStatut
							locationHref '/'
						return
				return
			return

		$scope.report = (status, $event) ->
			$($event.target)
				.parents('ul.dropdown-menu:first').trigger 'click'
			status.reported = true
			Ajax.get '/report/' + status._id, ->
				toastr.success s("Une alerte a été envoyée aux modérateurs de Wornet. Merci pour votre aide."), s "C'est fait"
			return

		$scope.sharedAlbumDefaultName = s("Publications d'amis")
		temporarySharedAlbumId = null
		at = getData 'at'
		$scope.onMe = !at or at is getData 'me'
		$scope.photoUploadAlbumId = getData 'photoUploadAlbumId'

		$scope.containsMedias = (status) ->
			status.containsMedias = true
			initMedias()
			if !$scope.onMe
				sharedAlbumId = getData('sharedAlbumId') || temporarySharedAlbumId
				if sharedAlbumId
					Ajax.get 'user/album/one/' + sharedAlbumId, (data) ->
						$scope.selectAlbum data.album._id
						refreshScope $scope
				else
					$scope.createAlbum {name: $scope.sharedAlbumDefaultName, description: ''}, at
					$scope.selectAlbum $('#album-select').val()
			else
				$scope.selectAlbum $('#album-select').val()
			return


		$scope.selectAlbum = (albumId) ->
			$scope.status.newAlbum = if albumId is "new"
				true
			else
				false
			$scope.currentAlbum = $.extend {}, _id: albumId
			$scope.status.lastSelectedAlbum = _id: albumId
			# initMedias()
			# loadNewIFrames()
			return

		$scope.createAlbum = (album, at) ->
			removeSessionItem albumKey()
			Ajax.put '/user/album/add',
				data:
					album: album
					at: at
				success: (data) ->
					if at
						temporarySharedAlbumId = data.album._id
						$scope.selectAlbum data.album._id
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
			if status.content || $scope.medias.images.length || $scope.medias.links.length
				data =
					data:
						status: status
						at: at
						medias: $scope.medias || null
						scannedLink: $scope.scannedLink
					success: (data) ->
						$scope.newStatusId = data.newStatus._id
						if $scope.scannedLink && !scanAllLinks $scope, status.content || ''
							Ajax.put '/user/link/add',
								data:
									link:
										name: $scope.scannedLink.link
										url: $scope.scannedLink.originalLink.replace /^(https?)?:?\/\//, ''
										https: $scope.scannedLink.originalLink.substr(0, 5) is 'https'
										referencedStatus: data.newStatus._id
										metaData: $scope.scannedLink
						$('.points').trigger 'updatePoints', [data.newStatus, true]
						setRecentStatus data, false
						if window.refreshMediaAlbums
							window.refreshMediaAlbums()
						resetStatus()

				if $scope.status.lastSelectedAlbum and $scope.status.lastSelectedAlbum._id is "new" and $scope.status.newAlbum and $("#album-name").val() isnt ""
					$.extend data.data,
						album:
							name: $("#album-name").val()
							description: $("#album-description").val()
				Ajax.put '/user/status/add' + getLastestUpdateChatId() + (if at then '/' + at else ''),	data

			return

		resetStatus = ->
			$scope.status.content = ""
			$scope.status.containsMedias = false
			$scope.status.newAlbum = false
			$("#album-name").val("")
			$("#album-description").val("")
			$('.status-link-preview').hide()
			initMedias()
			refreshScope $scope


		updateCommentList = (data) ->
			if data.commentList
				if !$scope.monoStatut
					for status in $scope.recentStatus
						if data.commentList[status._id]
							for comment in data.commentList[status._id]
								comment.content = richText $scope, comment.content, true, false
							status.comments = data.commentList[status._id]
							status.nbComment = data.commentList[status._id].length
							refreshScope $scope
							break
				else
					$scope.statusToDisplay.comments = data.commentList[$scope.statusToDisplay._id]
					$scope.statusToDisplay.nbComment = data.commentList[$scope.statusToDisplay._id].length
					refreshScope $scope

		$scope.sendComment = (status) ->
			if status.newComment
				comment = status.newComment
				statusMedias = $.extend {}, $scope.medias
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
			contentToDisplay = richText $scope, comment.content, true, false
			Ajax.post '/user/comment',
				data:
					comment: comment
				success: updateCommentList
			comment.content = contentToDisplay
			comment.originalContent = comment.content
			comment.edit = false
			refreshScope $scope
			return

		$scope.toggleCommentState = (comment) ->
			comment.edit = !comment.edit
			comment.content = if comment.edit
				unscanLink smiliesService.unfilter comment.content
			else
				comment.originalContent
			refreshScope $scope

		$scope.updateStatus = (status) ->
			#We have to do this before post because it also put videos in status.videos
			contentToDisplay = richText $scope, status.content, false, false, status
			Ajax.post '/user/status',
				data:
					status: status
			status.content = contentToDisplay
			$('.status-block[data-id="' + status._id + '"] .medias').removeClass('edit-status')
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
			if $('#displayLikers-' + status._id).length
				nbMore = $('#displayLikers-' + status._id + ' .more-liker').data 'nb-more'
				nbMore += if adding
					1
				else
					-1
				$('#displayLikers-' + status._id + ' .more-liker')
					.data 'nb-more', nbMore
					.html '+' + nbMore
			else
				if adding
					status.likers.push $scope.myPublicInfos
				else
					newLikers = []
					for liker in status.likers
						if liker.hashedId isnt $scope.myPublicInfos.hashedId
							newLikers.push liker
					status.likers = newLikers

			refreshScope $scope
			SingleAjax[if adding then 'put' else 'delete'] 'plusw' + status._id, '/user/plusw',
				data:
					status: status
					at: at
				success: (result) ->
					$('[data-id="'+status._id+'"] .btn-action-plus-w').removeAttr 'disabled'
					true

		$scope.nbCommentText = (status) ->
			s("Commentaire|Commentaires", null, status.nbComment)

		$scope.nbLikeText = (status) ->
			s("{nbLike} personne aime ça|{nbLike} personnes aiment ca", nbLike: status.nbLike, status.nbLike)

		$scope.nbShareText = (status) ->
			s("Partage|Partages", null, status.nbShare)

		$scope.isShareable = (status) ->
			conf = if status.at
				status.at.accountConfidentiality
			else
				status.author.accountConfidentiality
			conf is 'public'

		$scope.share = (status) ->
			if $scope.isShareable status
				Ajax.put '/user/status/share',
					data:
						statusId: status._id
					success: (result) ->
						status.nbShare++
						refreshScope $scope
						toastr.success s("Ce statut a été partagé sur votre profil."), s "C'est fait"


		at = getCachedData 'at'

		$scope.$on 'receiveStatus', (e, status) ->
			status.content = richText $scope, status.content
			me = getData 'me'
			if status.author and status.author.hashedId is me
				status.isMine = true
				status.concernMe = true
			else if status.at and status.at.hashedId is me
				status.isMine = false
				status.concernMe = true
			$scope.recentStatus.uniqueUnshift '_id', status
			refreshScope $scope
			if status.images and status.author and status.images.length and status.author.hashedId is at
				window.refreshMediaAlbums()
			return

		$scope.$on 'receiveComment', (e, comment) ->
			comment.isMine = comment.author.hashedId is getData 'me'
			comment.content = richText $scope, comment.content, true, false
			if !$scope.monoStatut
				for status in $scope.recentStatus
					if comment.attachedStatus and (status._id is comment.attachedStatus or status.referencedStatus is comment.attachedStatus)
						statusAt = status.at || status.author
						comment.onMyWall = statusAt.hashedId is getData 'me'
						(status.comments ||= []).uniquePush '_id', comment
			else
				statusAt = $scope.statusToDisplay.at || $scope.statusToDisplay.author
				comment.onMyWall = statusAt.hashedId is getData 'me'
				($scope.statusToDisplay.comments ||= []).uniquePush '_id', comment
			refreshScope $scope
			return

		window.statusScope = $scope

		$scope.status = containsMedias: false
		$scope.status.newAlbum = false
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

		$scope.toggleCommentBlock = (status) ->
			delay 1, ->
				if $scope.userConnected
					status.commentForm = !status.commentForm
				else
					status.commentForm = false
				status.commentList = !status.commentList
				refreshScope statusScope
				return
			return

		$scope.toggleStatusState = (status, edit) ->
			$('.status-block[data-id="' + status._id + '"] .medias')[if edit then 'addClass' else 'removeClass']('edit-status')
			status.edit = edit
			status.content = if edit
				unscanLink smiliesService.unfilter status.content
			else
				status.originalContent
			refreshScope $scope
			return

		lock = false
		$scope.displaylikerList = (status) ->
			if !lock and status.nbLike
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

		lock = false
		$scope.displaySharerList = (status) ->
			if !lock and status.nbShare
				lock = true
				Ajax.post '/user/share/list',
					data: status: status
					success: (data) ->
						window.shareListScope.lastsharersLoadedCount = data.sharers.length
						window.shareListScope.sharers = data.sharers
						window.shareListScope.status = status
						refreshScope window.shareListScope
						$('#sharer-list').modal 'show'
						lock = false
						return
			return

		delay 1, ->
			if !$scope.monoStatut
				Ajax.post $scope.getLoadUrl(),
					data: {}
					success: (data) ->
						setRecentStatus data

		refreshMediaAlbums()

		initMedias()
		$scope.monoStatut = false
		$scope.setMonoStatut = (val, status) ->
			$scope.monoStatut = val
			status.content = richText $scope, status.content
			status.nbComment = 0
			$scope.statusToDisplay = status
		delay 1, ->
			if $scope.monoStatut
				Ajax.bigGet 'user/comment',
					data:
						statusIds: [$scope.statusToDisplay._id]
					success: (data) ->
						if data.commentList
							[$scope.statusToDisplay].map (status) ->
								if data.commentList[status._id]
									status.comments = data.commentList[status._id]
									status.nbComment = data.commentList[status._id].length
								else
									status.nbComment = 0
								status.commentForm = status.commentList = !!(status.comments && status.comments.length)
								if !$scope.userConnected
									status.commentForm = false
								status
							refreshScope $scope
						return
				return
			else
				if $ '.album-select select option'
					$('.album-select select option').each (id, elem) ->
						if elem.value.indexOf('undefined') >= 0
							$(elem).remove()

		lastDelayIds = []
		lock = false
		$scope.scannedLink = {}
		$scope.cancelCheckLink = ->
			for lastDelayId in lastDelayIds
				clearTimeout lastDelayId
			lastDelayIds = []

		$scope.checkLink = ->
			(' ' + $scope.status.content)
				.replace /(\s)www\./g, '$1http://www.'
				.replace /(\s)(https?:\/\/\S+)/g, (all, space, link) ->
					lastDelayIds.push delay 1000, ->
						if !lock
							lock = true
							Ajax.post '/user/status/link/meta',
								data:
									url: link
								success: (res) ->
									lock = false
									if res.data
										$scope.medias.links = [
											href: link
											https: /^https:\/\//.test link
										]
										data = res.data

										linkMinimized = link.replace /^https?:\/\//g, ''
										if 0 < linkMinimized.indexOf '/'
											linkMinimized = linkMinimized.substring 0, linkMinimized.indexOf '/'
										$scope.scannedLink.link = linkMinimized
										$scope.scannedLink.originalLink = link
										unless rememberDissmissed[$scope.scannedLink.link] is "all"
											$('.status-link-preview span.link-preview-link').html linkMinimized
											$('.status-link-preview a.global-link-preview').attr('href', link)

											if data.ogImage and rememberDissmissed[$scope.scannedLink.link] isnt "img"
												$('.status-link-preview img.link-preview-image').attr('src', data.ogImage)
												$('.status-link-preview img.link-preview-image').show()
												$scope.scannedLink.image = data.ogImage
											else
												$('.status-link-preview img.link-preview-image').removeAttr('src')
												$('.status-link-preview img.link-preview-image').hide()
												$('.status-link-preview .dismiss-link-preview-image').hide()
												$scope.scannedLink.image = null
											if data.ogTitle || data.title
												$('.status-link-preview span.link-preview-title').attr('href', link).html(data.ogTitle || data.title)
												$scope.scannedLink.title = data.ogTitle || data.title
											else
												$('.status-link-preview span.link-preview-title').removeAttr('href').html('')
												$scope.scannedLink.title = null
											if data.ogDescription || data.description
												$('.status-link-preview span.link-preview-description').html(data.ogDescription || data.description)
												$scope.scannedLink.description = data.ogDescription || data.description
											else
												$('.status-link-preview span.link-preview-description').html('')
												$scope.scannedLink.description = null
											if data.author
												$('.status-link-preview span.link-preview-author').html(data.author)
												$scope.scannedLink.author = data.author
											else
												$('.status-link-preview span.link-preview-author').html('')
												$scope.scannedLink.author = null
											$('.status-link-preview').show()
											$('.status-link-preview .dismiss-link-preview-image').show()
											$('.status-link-preview .dismiss-link-preview').show()

		rememberDissmissed = {}
		$scope.dismissAllPreview = ->
			$('.status-link-preview').hide()
			rememberDissmissed[$scope.scannedLink.link] = "all"
			$scope.scannedLink = {}
			return

		$scope.dismissImagePreview = ->
			delete $scope.scannedLink.image
			$('.status-link-preview img.link-preview-image').hide()
			$('.status-link-preview .dismiss-link-preview-image').hide()
			rememberDissmissed[$scope.scannedLink.link] = "img"
			return

		$scope.adjustLikers = (statusId) ->
			elem = $('.status-block[data-id="' + statusId + '"] .like-details .liker-photos')
			nbChunk = 1 * elem.attr 'chunkPerLine'
			optimalMargin = elem.attr 'optimalmargin'
			if nbChunk
				if optimalMargin
					delay 1, ->
						$('.status-block[data-id="' + statusId + '"] .like-details .liker-photos img').css 'margin-right', optimalMargin + "px"
				for status in $scope.recentStatus
					if status._id is statusId
						if status.likers.length > nbChunk
							status.likers = status.likers.slice 0, nbChunk - 1
							refreshScope $scope
							elem.append '<a id="displayLikers-' + status._id + '" ><div class="likers-photo more-liker" data-nb-more="' + (status.nbLike - nbChunk + 1) + '">+' + (status.nbLike - nbChunk + 1) + '</div></a>'
							$('#displayLikers-' + status._id).on 'click', $scope.displaylikerList.bind $scope, status
						elem.removeClass "loading"
		return

	Suggests: ($scope) ->

		treatSuggest = (userHashedId, urlToCall) ->
			if userHashedId
				alreadyPresent = []
				newPublicUsers = []
				for user in $scope.publicUsers
					alreadyPresent.push user.hashedId
					unless user.hashedId is userHashedId
						newPublicUsers.push user
				if $scope.nextSuggest
					alreadyPresent.push $scope.nextSuggest.hashedId
					newPublicUsers.push $scope.nextSuggest
				$scope.publicUsers = newPublicUsers
				refreshScope $scope
				delay 1, ->
					$('.follow-suggest, .hide-suggest').prop 'disabled', true
					Ajax.put urlToCall,
						data:
							hashedId: userHashedId
							returnSuggest: true
							alreadyPresent: alreadyPresent
						success: (res) ->
							$('.follow-suggest, .hide-suggest').prop 'disabled', false
							if res.newUser
								$scope.nextSuggest = res.newUser
							else
								$scope.nextSuggest = null
							refreshScope $scope

							return


		$scope.follow = (userHashedId) ->
			treatSuggest userHashedId, "user/profile/follow"
			return

		$scope.hideSuggest = (userHashedId) ->
			treatSuggest userHashedId, "user/profile/hideSuggest"
			return

		$scope.nextSuggest = null
		delay 1, ->
			if $scope.publicUsers.length > 1
				$scope.nextSuggest = $scope.publicUsers.splice(-1)[0]
			else
				$scope.nextSuggest = null
			refreshScope $scope

		return

	Welcome: ($scope) ->
		removeSessionItem 'user'
		$(window).trigger('resize')
		$scope.send = ->
			selectedUsers = []
			$('input[type="checkbox"]').each (index, checkbox) ->
				if $(checkbox).is(':checked')
					selectedUsers.push $(checkbox).data 'user-hashedid'

			Ajax.put '/user/welcome',
				data:
					usersHashedId: selectedUsers
				success: ->
					locationHref '/' + $scope.userURLId

		return
