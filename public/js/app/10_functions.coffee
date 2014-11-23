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
						for v, i in value
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
				for v, i in value
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
	$('.errors').errors message || "Perte de la connexion internet. La dernière action n'a pas pu être effectuée."
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
	if window.sessionStorage
		for k, chat of chats
			for message in chat.messages
				if message.$$hashKey
					delete message.$$hashKey
		sessionStorage.chats = JSON.stringify chats
	$('.chat').show()
	keepScroll '.chat .messages'
	return

# Get chat messages and states from local session
getChats = ->
	$('.chat').show()
	keepScroll '.chat .messages'
	chats = {}
	try
		chats = objectResolve JSON.parse sessionStorage.chats
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

# Get albums from local storage or server
getAlbums = (done) ->
	albums = null
	try
		albums = objectResolve JSON.parse sessionStorage.albums
	catch e
		albums = null
	if typeof(albums) isnt 'object'
		albums = null
	if albums is null
		Ajax.get '/user/albums', (data) ->
			err = data.err || null
			if data.albums
				albums = data.albums
				sessionStorage.albums = JSON.stringify albums
			done err, albums
			return
	else
		done null, albums
	return
