# Save user datas on submit
saveUser = ($scope) ->
	$scope.submit = (user) ->
		user.remember = $('[ng-model="user.remember"]').prop 'checked'
		sessionStorage['user'] = JSON.stringify user
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

	if (['null', 'undefined']).indexOf(typeof value) isnt -1

		null

	else

		if typeof value isnt 'object'
			value = JSON.parse value

		key = 'resolvedCTBSWSydrqSuW2QyzUGMBTshU9SCJn5p'

		# First, convert the date and put the "resolved" key to do not reconvert
		enter = (value) ->
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
			if typeof(value) is 'object' and value[key]
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


# Shorthand to exec a callback (second parameter) after a delay
# (fisrt parameter) specified in milliseconds
delay = (ms, cb) ->
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
			Math.pow(10, mdp.length)

		# Mot de passe alphabétique mono-casse*
		when mdp.match(/^[a-z]+$/g) or mdp.match(/^[A-Z]+$/g)
			Math.pow(26, mdp.length)

		# Casses courantes :
		when mdp.match(/^[A-Z][a-z]+$/g) or mdp.match(/^[a-z]+[A-Z]$/g) or mdp.match(/^[a-z][A-Z]+$/g) or mdp.match(/^[A-Z]+[a-z]$/g)
			4 * Math.pow(26, mdp.length)

		# Mot de passe dont seule le premier caractère n'est pas une lettre et ou le reste est mono-casse*
		when mdp.match(/^.[a-z]+$/g) or mdp.match(/^.[A-Z]+$/g) or mdp.match(/^[a-z]+.$/g) or mdp.match(/^[A-Z]+.$/g)
			50 * Math.pow(26, mdp.length - 1)

		# Mot de passe alpha-numérique mono-casse*
		when mdp.match(/^[0-9a-z]+$/g) or mdp.match(/^[0-9A-Z]+$/g)
			Math.pow(36, mdp.length)

		# Mot de passe sans lettre
		when mdp.match(/^[^A-Za-z]+$/g)
			Math.pow(42, mdp.length)

		# Mot de passe sans nombre ni minuscule ou sans nombre ni majuscule
		when mdp.match(/^[^0-9a-z]+$/g) or mdp.match(/^[^0-9A-Z]+$/g)
			Math.pow(50, mdp.length)

		# Mot de passe alphabétique
		when mdp.match(/^[a-zA-Z\s]+$/g)
			Math.pow(52, mdp.length)

		# Mot de passe sans nombre ou sans minuscule ou sans majuscule
		when mdp.match(/^[^0-9]+$/g) or mdp.match(/^[^A-Z]+$/g) or mdp.match(/^[^a-z]+$/g)
			Math.pow(68, mdp.length)

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

# Refresh pill counter
refreshPill = ->
	$('.notifications').each ->
		$ul = $ @
		count = $ul.find('ul li').length
		if count
			$ul.find('.pill').show().text count
		else
			$ul.find('.pill').hide()
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
		unless typeof(elt.scrollHeight) isnt 'undefined' and ($this.scrollTop() is elt.scrollHeight - $this.height() or $this.is(':hidden'))
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
		for message in chat.messages
			if message.$$hashKey
				delete message.$$hashKey
		for user in chat.users
			if user.$$hashKey
				delete user.$$hashKey
	chatsCopy = JSON.parse JSON.stringify chats
	if window.sessionStorage
		for k, chat of chatsCopy
			for message in chat.messages
				if typeof(message.from) is 'object' and message.from.hashedId
					message.from = message.from.hashedId
				if typeof(message.to) is 'object' and message.to.hashedId
					message.to = message.to.hashedId
		sessionStorage.chats = JSON.stringify chatsCopy
	$('.chat').show()
	keepScroll '.chat .messages'
	chats

do (w = window) ->

	minimized = 1
	close = 2

	key = (chat) ->
		k = ''
		for user of chat.users
			for i, c of user.hashedId
				if i%3
					k += c
		k

	w.saveChatState = (chat) ->
		if window.localStorage
			localStorage[key(chat)] =
				if chat.minimized then minimized else 0 |
				if chat.open then 0 else close

	w.loadChatState = (chat) ->
		if window.localStorage
			opts = localStorage[key(chat.users)] || 0
			chat.minimized = !! (opts & minimized)
			chat.open = ! (opts & close)

# Get chat messages and states from local session
getChats = ->
	$('.chat').show()
	keepScroll '.chat .messages'
	chats = {}
	try
		chats = objectResolve JSON.parse sessionStorage.chats
		for k, chat of chats
			users = {}
			for user in chat.users
				users[user.hashedId] = user
			for message in chat.messages
				if typeof(message.from) is 'string'
					message.from = users[message.from]
				if typeof(message.to) is 'string'
					message.to = users[message.to]
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

# Get albums from server
getAlbumsFromServer = (done) ->
	if window.getAlbumsFromServer.waitingCallbacks
		window.getAlbumsFromServer.waitingCallbacks.push done
	else
		window.getAlbumsFromServer.waitingCallbacks = [done]
		at = (getData 'at') || ''
		if at
			at = '/with/' + at
		Ajax.get '/user/albums' + at, (data) ->
			err = data.err || null
			if data.albums
				albums = data.withAlbums || data.albums
				sessionStorage.albums = JSON.stringify albums
			for done in window.getAlbumsFromServer.waitingCallbacks
				done err, albums
			window.getAlbumsFromServer.waitingCallbacks = false
			return
		.error ->
			window.getAlbumsFromServer.waitingCallbacks = false
			return
	return

# Get albums from local storage or server
getAlbums = (done) ->
	albums = null
	if exists '.myMedias'
		try
			albums = objectResolve JSON.parse sessionStorage.albums
		catch e
			albums = null
		if typeof(albums) isnt 'object'
			albums = null
	if albums is null
		getAlbumsFromServer done
	else
		done null, albums
	return

# Refresh logged friends menu
loggedFriends = (friends) ->
	$('.loggedFriends').each ->
		$ul = $ @
		ul = ''
		ids = []
		$.each friends, ->
			if ids.indexOf(@hashedId) is -1
				ids.push @hashedId
				ul += '<li><a><img src="' + safeHtml(@thumb50) + '" alt="' + safeHtml(@name.full) + '" class="thumb">&nbsp; ' + safeHtml(@name.full) + ' &nbsp; <span class="glyphicon glyphicon-comment"></span></a></li>'
			return
		$ul.find('span.pill').text ids.length
		$ul.find('.dropdown-menu').html(ul).find('li a').each (key) ->
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

showLoader = ->
	$('.loader:last').css('z-index', 99999).removeClass 'preload'

hideLoader = ->
	$('.loader:last').css('z-index', '').addClass 'preload'

withFormData = (done) ->
	if typeof(FormData) is 'function'
		formData = new FormData()
		xhr = new XMLHttpRequest()
		done formData, xhr
		xhr.send formData
		false
	else
		true