# Local and session storages
errorsMuter = (ctx, callback) ->
	if callback
		callback = ctx[callback]
	else
		callback = ctx
		ctx = null
	->
		try
			callback.apply (ctx || @), arguments
		catch error
			console.warn error
			return

do =>

	storageEngines =
		session: 'Session'
		local: 'Local'

	for key, name of storageEngines
		engine = @[key + 'Storage'] || {}
		@['get' + name + 'Item'] = errorsMuter engine, 'getItem'
		@['set' + name + 'Item'] = errorsMuter engine, 'setItem'
		@['get' + name + 'Value'] = errorsMuter do (engine) ->
			(key) ->
				$.parseJSON engine.getItem key
		@['set' + name + 'Value'] = errorsMuter do (engine) ->
			(key, value) ->
				engine.setItem key, JSON.stringify value
		@['has' + name + 'Item'] = errorsMuter engine, 'hasOwnProperty'
		@['remove' + name + 'Items'] = errorsMuter engine, 'clear'
		@['remove' + name + 'Item'] = errorsMuter engine, 'removeItem'

# Compatible location.href set
locationHref = (url) ->
	location.href = url
	return

# Save user data on submit
saveUser = ($scope) ->
	$scope.submit = (user) ->
		user.remember = $('[ng-model="user.remember"]').prop 'checked'
		setSessionValue 'user', user
		return
	return

# Preserve the form data already tiped by the user before $scope loaded
keepTipedModel = ($scope, selector, modelName) ->
	model = {}
	$(selector + ' [ng-model^="' + modelName + '."]').each ->
		$input = $ @
		name = $input.attr('ng-model').substr(modelName.length + 1)
		model[name] = $input.val()
	$scope[modelName] = model

# Resolve object get from template (passed in JSON)
# Restore date object converted to strings previously (by JSON stringification)
objectResolve = (value) ->

	if value in [null, undefined]

		null

	else

		if typeof value isnt 'object'
			try
				value = JSON.parse value
			catch e
				value = null

		key = 'resolvedCTBSWSydrqSuW2QyzUGMBTshU9SCJn5p'

		# First, convert the date and put the "resolved" key to do not reconvert
		enter = (value) ->
			unless value in [null, undefined]
				switch typeof(value)
					when 'object'
						unless value[key]
							for i, v of value
								value[i] = enter value[i]
							value[key] = true
					when 'string'
						if /^[0-9-]+T[0-9:.]+Z$/.test value
							date = new Date value
							if `date != 'Invalid Date'`
								value = date
			value

		# Then, remove all the "resolved" keys
		leave = (value) ->
			if value not in [null, undefined] and typeof(value) is 'object' and value[key]
				delete value[key]
				for i, v of value
					value[i] = leave value[i]
			value

		leave enter value


# To know if a object or selector exists
exists = (sel) ->
	!!$(sel).length


# Function to get a data passed throught the template
getData = (name) ->
	name = name.replace /(\\|")/g, '\\$1'
	$data = $ '[data-data][data-name="' + name + '"]'
	unless exists $data
		console.warn name + " data not found."
		console.trace()
	objectResolve $data.data 'value'

# Store the getData as a chached value
getCachedData = do ->
	data = {}
	(name) ->
		if data.hasOwnProperty name
			data[name]
		else
			data[name] = getData name


# Shorthand to exec a callback (second parameter) after a delay
# (fisrt parameter) specified in milliseconds
delay = (ms, cb) ->
	if typeof ms is 'function'
		cb = ms
		ms = 50
	setTimeout cb, ms


# Escape HTML entities < and >
safeHtml = (val) ->
	$('<div/>').text(val).html()


# Return strongness level of a password
passwordStrongness = (mdp) ->

	#
	#	Les types de mot de passe sont classés du plus résistant au plus fragile.
	#	Un facteur est alors déterminé en fonction du nombre de possibilités à
	#	tester pour un robot et ce facteur est élevé à la puissance mdp.length
	#	correspondant au nombre de caractères à cracker.
	#	La fonction retourne donc une approximation très proche du nombre de tests
	#	que doit lancer une attaque de force brute pour essayer toutes les
	#	combinaisons pour un type de mot de passe donné.
	#
	#	*mono-casse : tout en majuscules ou tout en minuscules
	#

	switch
		# Mot de passe vide
		when mdp is ""
			0

		# Mot de passe numérique
		when mdp.match(/^[0-9]+$/g)
			Math.pow 10, mdp.length

		# Mot de passe alphabétique mono-casse*
		when mdp.match(/^[a-z]+$/g) or mdp.match(/^[A-Z]+$/g)
			Math.pow 26, mdp.length

		# Casses courantes :
		when mdp.match(/^[A-Z][a-z]+$/g) or mdp.match(/^[a-z]+[A-Z]$/g) or mdp.match(/^[a-z][A-Z]+$/g) or mdp.match(/^[A-Z]+[a-z]$/g)
			4 * Math.pow 26, mdp.length

		# Mot de passe dont seule le premier caractère n'est pas une lettre et ou le reste est mono-casse*
		when mdp.match(/^.[a-z]+$/g) or mdp.match(/^.[A-Z]+$/g) or mdp.match(/^[a-z]+.$/g) or mdp.match(/^[A-Z]+.$/g)
			50 * Math.pow 26, mdp.length - 1

		# Mot de passe alpha-numérique mono-casse*
		when mdp.match(/^[0-9a-z]+$/g) or mdp.match(/^[0-9A-Z]+$/g)
			Math.pow 36, mdp.length

		# Mot de passe sans lettre
		when mdp.match(/^[^A-Za-z]+$/g)
			Math.pow 42, mdp.length

		# Mot de passe sans nombre ni minuscule ou sans nombre ni majuscule
		when mdp.match(/^[^0-9a-z]+$/g) or mdp.match(/^[^0-9A-Z]+$/g)
			Math.pow 50, mdp.length

		# Mot de passe alphabétique
		when mdp.match(/^[a-zA-Z\s]+$/g)
			Math.pow 52, mdp.length

		# Mot de passe sans nombre ou sans minuscule ou sans majuscule
		when mdp.match(/^[^0-9]+$/g) or mdp.match(/^[^A-Z]+$/g) or mdp.match(/^[^a-z]+$/g)
			Math.pow 68, mdp.length

		# Mot de passe complexe
		else
			Math.pow 100, mdp.length

# Delete a friend ask by id
deleteFriendAsk = (id) ->
	$('.friend-ask[data-id="' + id + '"]').each ->
		$this = $ @
		$li = $this.parents 'li:first'
		if exists $li
			$li.remove()
		else
			$this.remove()
		return
	return

notificationPrint = (elt) ->
	clone = $(elt).clone true
	clone.detach '.date'
	encodeURIComponent($(elt).clone().remove('.date').text().replace(/\s/g, '')) + ','

refreshPillOfList = (elt) ->
	$ul = $ elt
	count = $ul.find('ul li').not('.read, .activities-list, .read-all, .divider').length
	$ul.find('.pill').css('visibility', 'visible').text count
	return

# Refresh pill counter
refreshPill = ->
	$('.notifications, .notifications-mobile').each ->
		refreshPillOfList @
		return
	return

# Execute a callback when recorded then each time the window is resized
onResize = (fct) ->
	$(window).resize fct
	fct.call @
	return

# Display error message or default message
serverError = (message) ->
	$('.errors').errors message || SERVER_ERROR_DEFAULT_MESSAGE
	return

# Shorthand to stop event propagation and return false
stop = (e) ->
	e.stopPropagation()
	false

# Shorthand to prevent default behavior and return false
prevent = (e) ->
	e.preventDefault()
	false

# Shorthand to stop event propagation, prevent default behavior and return false
cancel = (e) ->
	stop e
	prevent e

# Restore scroll after a dom change in a block
keepScroll = (sel) ->
	excludeElements = []
	$(sel).each ->
		$this = $ @
		elt = $this[0]
		unless typeof(elt.scrollHeight) isnt 'undefined' and (($this.scrollTop() > elt.scrollHeight - $this.height() - 5) or $this.is(':hidden'))
			excludeElements.push elt
		return
	delay 1, ->
		checkDates()
		$(sel).each ->
			$this = $ @
			elt = $this[0]
			for i in excludeElements
				if i is elt
					return
			$this.scrollTop elt.scrollHeight - $this.height()
			return
		return
	return

# Save chat messages and states in local session
saveChats = (chats) ->
	for k, chat of chats
		if k
			for message in chat.messages
				if message.$$hashKey
					delete message.$$hashKey
			for user in chat.users
				if user.$$hashKey
					delete user.$$hashKey
		else
			delete chats[k]
	chatsCopy = JSON.parse JSON.stringify chats
	if window.sessionStorage
		for k, chat of chatsCopy
			for message in chat.messages
				if typeof(message.from) is 'object' and message.from.hashedId
					message.from = message.from.hashedId
				if typeof(message.to) is 'object' and message.to.hashedId
					message.to = message.to.hashedId
		setSessionValue 'chats', chatsCopy
	$('.chat').show()
	keepScroll '.chat .messages'
	chats

do =>

	minimized = 1
	close = 2

	key = (chat) ->
		k = ''
		for user in chat.users
			for i, c of user.hashedId
				if i%3
					k += c
		k

	@saveChatState = (chat) ->
		setLocalItem key(chat),
			if chat.minimized then minimized else 0 |
			if chat.open then 0 else close

	@loadChatState = (chat) ->
		opts = getLocalItem(key chat) | 0
		chat.minimized = !! (opts & minimized)
		chat.open = ! (opts & close)

# Get chat messages and states from local session
getChats = ->
	$('.chat').show()
	keepScroll '.chat .messages'
	chats = {}
	try
		chats = (objectResolve getSessionValue 'chats') || {}
		for k, chat of chats
			users = {}
			if chat.users and chat.users.length
				for user in chat.users
					users[user.hashedId] = user
				for message in chat.messages
					if typeof(message.from) is 'string'
						message.from = users[message.from]
					if typeof(message.to) is 'string'
						message.to = users[message.to]
			else
				delete chats[k]
	catch e
		chats = {}
	if typeof(chats) isnt 'object'
		chats = {}
	chats

# Apply modifications in scope variables then refresh date
refreshScope = ($scope) ->
	unless $scope.$root.$$phase is '$apply' or $scope.$root.$$phase is '$digest'
		$scope.$apply()
	checkDates()
	return

albumKey = ->
	at = (getCachedData 'at') || (getCachedData 'me')
	'albums-' + at

# Get albums from server
getAlbumsFromServer = (done) ->
	if window.getAlbumsFromServer.waitingCallbacks
		window.getAlbumsFromServer.waitingCallbacks.push done
	else
		window.getAlbumsFromServer.waitingCallbacks = [done]
		at = (getCachedData 'at') || ''
		key = albumKey()
		if !at
			at = (getCachedData 'me') || ''
		Ajax.get 'user/albums/medias/' + at, (data) ->
			err = data.err || null
			if data.albums
				albums = removeDeprecatedAlbums( data.withAlbums || data.albums )
				setSessionValue key, albums
			for done in window.getAlbumsFromServer.waitingCallbacks
				if data.nbAlbums and data.user
					done err, albums, data.nbAlbums, data.user
				else
					done err, albums
			window.getAlbumsFromServer.waitingCallbacks = false
			return
		.error ->
			window.getAlbumsFromServer.waitingCallbacks = false
			return
	return

# Get albums from local storage or server
getAlbums = (done) ->
	done ||= ->
	albums = null
	if exists '.myMedias'
		if getCachedData 'at'
			try
				albums = objectResolve getSessionValue albumKey()
			catch e
				albums = null
		if typeof(albums) isnt 'object'
			albums = null
	if albums is null
		getAlbumsFromServer done
	else
		done null, removeDeprecatedAlbums albums
	return

removeDeprecatedAlbums = (albums) ->
	today = new Date
	sixDaysEarlier = today.subDays 6
	results = []
	if albums
		for id, album of albums
			if !album.lastEmpty or (album.lastEmpty and (new Date(album.lastEmpty) > sixDaysEarlier or album.preview.length isnt 0))
				if typeof(album) isnt "function"
					results.push album
	results

# Refresh logged friends menu
loggedFriends = (friends) ->
	$('.loggedFriends, .loggedFriends-mobile').each ->
		$ul = $ @
		ul = ''
		ids = []
		$.each friends, ->
			if ids.indexOf(@hashedId) is -1
				ids.push @hashedId
				ul += '<li><a><img src="' + safeHtml(@thumb50) + '" alt="' + safeHtml(@name.full) + '" class="thumb">&nbsp; <span class="user-name">' + safeHtml(@name.full) + '&nbsp; </span><span class="glyphicon glyphicon-comment"></span></a></li>'
			return

		$ul.find('span.pill').text ids.length

		if ul is ''
			s = textReplacements
			ul = '<li><a><span class="no-logged-friend">' + s('Aucun ami connecté pour le moment.') + '</span></a></li>'

		$dropdown = $ul.find '.dropdown-menu'
		if ! $ul.hasClass 'loggedFriends-mobile'
			$dropdown.find('li:not(.select-chat-sound, .divider)').remove()
			$dropdown.prepend(ul).find('li:not(.select-chat-sound) a').each (key) ->
				$(@).click ->
					chatService.chatWith [objectResolve friends[key]]
					return
				return
		else
			$dropdown.html(ul).find('li:not(.select-chat-sound) a').each (key) ->
				$(@).click ->
					chatService.chatWith [objectResolve friends[key]]
					return
				return
		return
	return

# Get id from an image URL
idFromUrl = (url) ->
	id = ('' + url).replace /^.+\/photo\/([0-9]+x)?([0-9a-f]+)[\/.x].+$/ig, '$2'
	if id is url
		null
	else
		id

# Parse iframe contents and append iFramesParsed class to their container
loadNewIFrames = ->
	delay 1, ->
		$('iframe').each ->
			$area = $(@).parent()
			unless $area.hasClass 'iFramesParsed'
				$area.addClass 'iFramesParsed'
				for evt in loadIFrameEvents
					do (evt = evt) ->
						$iframe = $area.find evt[0]
						$iframe.load ->
							args = Array.prototype.slice.call arguments
							args.unshift $ @
							evt[1].apply @, args
							return
					return
			return
		return
	return

# Escape RegExp symbols
regExpEscape = (text) ->
	text.replace /[\-\[\]\/\{\}\(\)\*\+\?\.\\\^\$\|]/g, "\\$&"

# Make loading animations visible
showLoader = ->
	$('.loader:last').css('z-index', 99999).removeClass 'preload'

# Make loading animations hidden
hideLoader = ->
	$('.loader:last').css('z-index', '').addClass 'preload'

# Send form if FormData is not suported
withFormData = ($form, done) ->
	s = textReplacements
	if 'function' is typeof $form
		done = $form
		$form = null
	if 'function' is typeof FormData
		formData = new FormData()
		xhr = new XMLHttpRequest()
		done formData, xhr
		xhr.send formData
		false
	else
		if $form
			sum = 0
			$form.find('input[type="file"]').map (input) ->
				sum += if input and input.files and input.files.length
					input.files.length
				else
					1
			$form.find('.upload-label').text if sum > 1
				s("Envoi des images en cours...")
			else
				s("Envoi de l\'image en cours...")
			$form[0].submit()
		true

# Get {count} lastest elements of {arr}
lastest = (arr, count) ->
	if arr instanceof Array
		res = if count < arr.length
			arr.slice arr.length - count
		else
			arr.slice()
		res.reverse()
		res
	else
		res = {}
		for key in lastest Object.keys(arr), count
			res[key] = arr[key]

# Send AJAX status to make a notification read
readNotification = (id) ->
	$('[data-id="' + id + '"]').addClass 'read'
	Ajax.get '/user/notify/read/' + id

mp3 = (name) ->
	"/resources/mp3/"+name+".mp3"

infoDialog = (title, message, labelOk, labelKo, done) ->
	if 'function' is typeof labelOk
		done = labelOk
		labelOk = "Oui"
		labelKo = "Non"
	s = textReplacements
	bootbox.dialog
		message: message,
		title: title,
		buttons:
			cancel:
				label: labelKo,
				className: "btn",
				callback: ->
					done false
			main:
				label: labelOk,
				className: "btn-primary",
				callback: ->
					done true

template = do ->
	version = $('link[href*="/app.css?"], link[href*="/all.css?"]').prop('href').split('?')[1]
	(src) ->
		'/template' + src + '?' + version

# Track an event and send it to analytics tools
trackEvent = do ->
	lastKey = ''
	lastTime = 0
	elts = 'a,button,img,input[type="button"],input[type="submit"],input[type="file"],[ng-click]'
	(e, b, c) ->
		if e.target
			if @ is e.target
				$btn = $ @
				unless $btn.is elts
					$btn = $btn.parents elts
				if exists $btn
					btn = $btn[0]
					$btn = $ btn
					id = $btn.attr 'id'
					id = if id then '#' + id else ''
					classes = $btn.attr 'class'
					classes = if classes then '.' + classes.split(/\s+/)[0] else ''
					selector = btn.tagName.toLowerCase() + id + classes
					label = $btn.text() || $btn.val() || $btn.attr('title') || $btn.attr('alt') || 'Sans libellé'
					trackEvent 'Clic', selector, label
		else
			time = $.now()
			key = e + '-' + b + '-' + c
			if time - lastTime > 500 or lastKey isnt key
				window['_' + 'paq'].push ['trackEvent', e, b, c]
				lastTime = time
				lastKey = key

Array.uniqueMethod = (method) ->
	(key) ->
		args = Array.prototype.slice.call arguments, 1
		for arg in args
			present = do =>
				for obj in @
					if obj[key] is arg[key]
						return true
				false
			unless present
				@[method] arg

Array::uniquePush = Array.uniqueMethod 'push'

Array::uniqueUnshift = Array.uniqueMethod 'unshift'

getLastestUpdateChatId = ->
	lastestDate = ''
	chats = getChats()
	for id, chat of chats
		for message in chat.messages
			dateToTest = new Date message.date
			if !lastestDate or dateToTest > lastestDate
				lastestDate = dateToTest
	if lastestDate
		'/' + lastestDate.getTime()
	else
		'/0'

window.isMe = (hashedId) ->
	hashedId is getCachedData('me')

window.isMobile = ->
	if window.matchMedia
		!! window.matchMedia("(max-width:767px)").matches
	else
		window.innerWidth < 768

videoHosts =
	'//www.dailymotion.com/embed/video/$1': [
		[/^dai\.ly\/([a-z0-9_-]+)/i, 1]
		[/^dailymotion\.com\/video\/([a-z0-9_-]+)/i, 1]
	]
	'//www.youtube.com/embed/$1': [
		[/^youtu\.be\/([a-z0-9_-]+)/i, 1]
		[/^youtu\.be\/([a-z0-9_-]+)\?t=([0-9]+)/i, 2]
		[/^youtube\.com\/watch\?v=([a-z0-9_-]+)/i, 1]
		[/^youtube\.com\/watch\?t=([0-9]+)(\&|\&amp;)v=([a-z0-9_-]+)/i, 3]
	]

richText = ($scope, text, transformToLinks = true, displayVideoLink, status = null) ->
	scanAllLinks $scope, smiliesService.filter(text), transformToLinks, displayVideoLink, status

scanAllLinks = ($scope, text, transformToLinks = false, displayVideoLink, status) ->
	((' ' + text)
		.replace /(\s)www\./g, '$1http://www.'
		.replace /(\s)(https?:\/\/\S+)/g, (all, space, link) ->
			if transformToLinks
				space + scanLink $scope, link, false, displayVideoLink
			else
				ret = scanLink $scope, link, true, false, status
				if status
					space + ret
				else
					all
	).substr 1

scanLink = ($scope, href, sendMedia = true, displayVideoLink = false, status = null) ->
	https = href.substr(0, 5) is 'https'
	href = href.replace /^(https?)?:?\/\//, ''
	test = href.replace /^www\./, ''
	video = do ->
		for url, regexps of videoHosts
			for regexp in regexps
				fieldToKeep = regexp[1]
				match = test.match regexp[0]
				if match and match.length > 1
					return url.replace '$1', match[fieldToKeep]
		null
	s = textReplacements
	if video
		if sendMedia
			if status
				status.videos.push
					href: video
					concernMe: true
					statusId: status._id
				refreshScope $scope
				return ''
			else
				$scope.medias.videos.push
					href: video
			Ajax.put '/user/video/add', video: url: video
			return
		else
			# '<a href=' + JSON.stringify(video) + '>' + s("Voir la vidéo") + '</a>'
			if displayVideoLink
				hrefToDisplay = if href.length > 34
					href.substr(0, 34) + '...'
				else
					href
				'<a target="_blank" href=' + JSON.stringify('http://' + href) + '>' + hrefToDisplay + '</a>'
			else
				''
	else
		if sendMedia
			if status
				status.links = status.links.filter (link) ->
					link.href isnt href
				status.links.push
					href: href
					https: https
				refreshScope $scope
				hrefToDisplay = if href.length > 34
					href.substr(0, 34) + '...'
				else
					href
				return '<a target="_blank" href=' + JSON.stringify('http://' + href) + '>' + hrefToDisplay + '</a>'
			else
				$scope.medias.links.push
					href: href
					https: https
			Ajax.put '/user/link/add', link:
				name: href
				url: href
				https: https
			return
		else
			hrefToDisplay = if href.length > 34
				href.substr(0, 34) + '...'
			else
				href
			'<a target="_blank" href=' + JSON.stringify('http://' + href) + '>' + hrefToDisplay + '</a>'
