Controllers =

	Login: ($scope) ->
		# Get remember preference of the user if previously saved (default: true)
		$scope.user.remember = (if localStorage then !!localStorage['user.remember'] else true)
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
						location.href = data.goingTo
					# Else : an error occured
					else
						errors = data.err || "Erreur"
						if typeof(errors) isnt 'object'
							errors = [errors]
						$errors = $('#loginErrors').html('') # Get and empty the #loginErrors block
						# Append each error
						for error in errors
							$errors.append('<div class="alert alert-danger">' + error + '</div>')
						# Close (instantanly) the error block
						$errors.slideUp(0).slideDown('fast')

	Signin: ($scope) ->
	# 	$scope.submit = (user) ->
	# 		Ajax.page (done, cancel) ->
	# 			user._method = "PUT"
	# 			user._csrf = user._csrf || $('head meta[name="_csrf"]').attr 'content'
	# 			$.post '/user/signin', user, (data) ->
	# 				$errors = $(data).find('#signinErrors .alert')
	# 				if $errors.length
	# 					cancel data
	# 					$('#signinErrors').append $errors
	# 				else
	# 					done data

	Calendar: ($scope, $route) ->
		window.$scope = $scope
		$page.load ->
			window.$scope = $scope
			console.log $scope
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
						if cb?
							cb(data)


		# On click on an event, a modal bootstrap window displays allowing user to
		# enter a description content
		$scope.editContent = (event, allDay, jsEvent, view) ->
			$scope.eventToEdit = $.extend {}, event
			$('#eventContent').modal()


		# When user save the event description content
		$scope.saveContent = (event, allDay, jsEvent, view) ->
			for ev, index in $scope.events
				if ev.id is event.id
					ev.content = event.content
					$scope.saveEvent ev
					break


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
					event.id = data._id
			# After new field is ready (after AngularJS create it)
			delay 50, ->
				# Give the focus to the new field
				$('ul.events input[ng-model="e.title"]:last').focus()


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


		# When switch to day/week/month mode
		$scope.changeView = (view, calendar) ->
			calendar.fullCalendar "changeView", view


		# Init calendar
		$scope.renderCalender = (calendar) ->
			calendar.fullCalendar "render"


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


# Resolve object get from template (passed in JSON)
# Restore date object converted to strings previously (by JSON stringification)
objectResolve = (value) ->

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


# Function to get a data passed throught the template
getData = (name) ->
	name = name.replace /(\\|")/g, '\\$1'
	$data = $ '[data-data][data-name="' + name + '"]'
	unless $data.length
		console.warn name + " data not found."
		console.trace()
	objectResolve $data.data 'value'


# Shorthand to exec a callback (second parameter) after a delay
# (fisrt parameter) specified in milliseconds
delay = (ms, cb) ->
	setTimeout cb, ms


# Send HTTP GET, POST, PUT and DELETE request through AJAX
Ajax =
	###
	Send a GET AJAX request

	@param string request URL
	@param object|function jQuery AJAX settings object or success callback function
	@param string HTTP method to emulate (DELETE, PUT, HEAD)
	@param defaultType GET or POST

	@return XHR object (+ jQuery extra stuff)
	###
	get: (url, settings, _method, defaultType = "GET") ->
		# If the second parameter is a function, we use it as success callback
		if typeof(settings) is 'function'
			settings =
				success: settings
		settings.type = settings.type || defaultType
		# Get JSON response by default
		settings.dataType = settings.dataType || "json"
		settings.data = settings.data || {}
		# Append CSRF token (needed for security)
		settings.data._csrf = settings.data._csrf || $('head meta[name="_csrf"]').attr 'content'
		# If method isnt GET or POST, it must be emulated
		if _method?
			# Set method in data POST parameters
			settings.data._method = _method
		$.ajax url, settings

	###
	Send a POST AJAX request

	@param string request URL
	@param object|function jQuery AJAX settings object or success callback function
	@param string HTTP method to emulate (DELETE, PUT, HEAD)

	@return XHR object (+ jQuery extra stuff)
	###
	post: (url, settings, _method) ->
		@get url, settings, _method, "POST"

	###
	Send a PUT AJAX request

	@param string request URL
	@param object|function jQuery AJAX settings object or success callback function

	@return XHR object (+ jQuery extra stuff)
	###
	put: (url, settings) ->
		@post url, settings, "PUT"

	###
	Send a DELETE AJAX request

	@param string request URL
	@param object|function jQuery AJAX settings object or success callback function

	@return XHR object (+ jQuery extra stuff)
	###
	delete: (url, settings) ->
		@post url, settings, "DELETE"

	contentSelector: '[role="main"]'
###
	page: (param) ->
		selector = @contentSelector
		$children = $page.find('> *').detach()
		$page.html '<div class="loader"></div>'
		get$data = (data) ->
			$data = $ data
			$csrf = $data.find 'head meta[name="_csrf"]'
			if $csrf.length
				$('head meta[name="_csrf"]').attr 'content', $csrf.attr('content')
			$data
		if typeof(param) is 'function'
			param.call @, (data) ->
				data = get$data(data).find selector
				$page.html(data).fadeOut(0).fadeIn()
				$page.trigger 'load'
			, (data) ->
				get$data data
				$page.html('').append $children
				$page.trigger 'load'
		else
			$page.load param + ' ' + selector, ->
				$page.trigger 'load'
		false
###


$page = $ Ajax.contentSelector


###
Crud can send request to its member URL
###
class Crud
	constructor: (url = '/') ->
		@url = url

	url: (url = '/') ->
		new Crud @url + url

	get: (settings, _method, defaultType) ->
		Ajax.get @url, settings, _method, defaultType

	post: (settings, _method) ->
		Ajax.post @url, settings, _method

	put: (settings) ->
		Ajax.put @url, settings

	delete: (settings) ->
		Ajax.delete @url, settings


# To permit to a 0 opacity HTML element to fade
$.fn.readyToFade = ->
	if @.css('opacity') is '0'
		@.css('opacity', '1').fadeOut(0)
	@


$(document)
	# When receive back an AJAX request
	.ajaxComplete (event, xhr, settings) ->
		# POST is secured by CSRF tokens
		if settings.type is "POST"
			data = xhr.responseText
			# In JSON format
			if settings.dataType? && settings.dataType.toLowerCase() is "json"
				window.xhr = xhr
				data = $.parseJSON data
				if typeof(data) isnt 'object'
					console.warn 'JSON data response is not an object'
					console.trace()
				else if typeof(data.err) isnt 'undefined'
					err = data.err
				_csrf = data._csrf
			# In HTML format
			else
				# Get new CSRF token from meta tags given in the AJAX response
				_csrf = $(data).find('meta[name="_csrf"]').attr 'content'
		$('head meta[name="_csrf"]').attr 'content', _csrf
		throw err if err?

	.on 'focus', '.form-control', ->
		$(@).prev('.tooltip').readyToFade().fadeIn('fast')

	.on 'blur', '.form-control', ->
		$(@).prev('.tooltip').fadeOut('fast')

	.on 'keyup focus change click', '.check-pass', ->
		$password = $(@).find('input[type="password"]')
		$security = $(@).find('.pass-security').removeClass('verylow low medium high veryhigh')
		strongness = passwordStrongness $password.val()
		switch
			when strongness > 10000000000000000
				$security.addClass('veryhigh')
			when strongness > 10000000000000
				$security.addClass('high')
			when strongness > 1000000000
				$security.addClass('medium')
			when strongness > 1000000
				$security.addClass('low')
			else
				$security.addClass('verylow')

# AJAX Navigation
.on 'click', '.link', (event) ->
	Ajax.page $(@).attr('href')


dateTexts = getData('dateTexts')

calendarGetText = (name) ->
	if typeof(dateTexts[name]) is 'undefined'
		console.warn name + " calendar text not found."
		console.trace()
	dateTexts[name]


lang = $('html').attr 'lang'
shortLang = lang.split(/[^a-zA-Z]/)[0]


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


Wornet = angular.module 'Wornet', [
	'ui.calendar'
	'ui.bootstrap'
]


for controller, method of Controllers
	Wornet.controller controller + 'Ctrl', ['$scope', method]
