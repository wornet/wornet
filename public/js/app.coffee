Controllers =

	Login: ($scope) ->
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
						location.href = data.goingTo
					# Else : an error occured
					else
						$('#loginErrors').errors data.err

	SigninFirstStep: ($scope) ->
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


$.fn.extend
	# Append errors to the given jQuery block
	# Then slide them out
	errors: (errors) ->
		errors = errors || "Erreur"
		if typeof(errors) isnt 'object'
			errors = [errors]
		@.html('') # Get and empty the #loginErrors block
		# Append each error
		for error in errors
			@.append('<div class="alert alert-danger">' + error + '</div>')
		# Close (instantanly) the error block
		@.slideUp(0).slideDown('fast')
	# To permit to a 0 opacity HTML element to fade
	readyToFade: ->
		if @.css('opacity') is '0'
			@.css('opacity', '1').fadeOut(0)
		@
	# Circular progress load animation
	circularProgress: (ratio, color) ->
		color = color || ($('<div class="ref-color"></div>').css('color') || '#ff8800')
		bgCol = @.css('background-color')
		if ratio < 0.5
			@.css('background-image', 'linear-gradient(90deg, ' + bgCol + ' 50%, transparent 50%, transparent), linear-gradient(' + Math.round(360 * ratio + 90) + 'deg, ' + color + ' 50%, ' + bgCol + ' 50%, ' + bgCol + ')')
		else
			@.css('background-image', 'linear-gradient(' + Math.round(90 + 360 * ratio) + 'deg, ' + color + ' 50%, transparent 50%, transparent), linear-gradient(270deg, ' + color + ' 50%, transparent 50%, transparent)')


$(document)
	# When receive back an AJAX request
	.ajaxComplete (event, xhr, settings) ->
		# POST is secured by CSRF tokens
		if settings.type is "POST"
			data = xhr.responseText
			# In JSON format
			if settings.dataType? && settings.dataType.toLowerCase() is "json"
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

	.on 'error', 'img.upload-thumb', ->
		$thumb = $(@)
		$input = $thumb.parent().find('input.upload')
		$('.errors').errors $input.data('error')

	.on 'error load', 'img.upload-thumb', ->
		$(@).parent().find('.loader').remove()

	.on 'change', 'input.upload', ->
		$input = $ @
		$parent = $input.parent()
		$thumb = $parent.find 'img.upload-thumb'
		#$thumb.prop 'src', $input.val()
		$('<div class="loader"></div>').appendTo($parent).fadeOut(0).fadeIn('fast')
		$input.parents('form').submit()

	.on 'load', 'iframe', ->
		$iframe = $ @
		name = $iframe.attr 'name'
		$form = $ 'form[target="' + name + '"]'
		$img = []
		$loader = $form.find '.loader'
		$loader.fadeOut 'fast', $loader.remove
		if $form.length
			$img = $('img', $iframe.prop('contentWindow'))
		if $img.length && $img[0].width > 0
			$form.find('img.upload-thumb').prop 'src', $img.prop('src')
		else
			$('.errors').errors $form.find('input.upload').data('error')

	.on 'submit', '#profile-photo', (evt) ->
		$form = $ @
		$img = $form.find 'img.upload-thumb'
		$img.fadeOut('fast')
		if typeof(FormData) is 'function'
			$progress = $form.find '.progress-radial'
			evt.preventDefault()
			formData = new FormData()
			file = $form.find('input[type="file"]')[0].files[0]
			formData.append 'photo', file
			formData.append '_csrf', $('head meta[name="_csrf"]').attr('content')

			xhr = new XMLHttpRequest()
			xhr.open 'POST', $form.prop('action'), true

			xhr.upload.onprogress = (e) ->
				if e.lengthComputable
					$progress.circularProgress e.loaded / e.total

			xhr.onerror = ->
				$error = $(@responseText)
				unless $error.is('.error')
					$error = $error.find '.error'
				$loader = $form.find '.loader'
				$loader.fadeOut 'fast', $loader.remove
				$('.errors').errors $error.html()

			xhr.onload = ->
				$newImg = $(@responseText)
				unless $newImg.is('.error') || $newImg.is('img')
					$newImg = $newImg.find 'img'
				if $newImg.is('img')
					newSource = $newImg.attr('src')
					$img.fadeOut 'fast', ->
						$loader = $form.find '.loader'
						$loader.fadeOut 'fast', $loader.remove
						$img.attr('src', newSource).fadeIn('fast')
				else
					@onerror()

			xhr.send formData
			false
		else
			true

	.on 'click', '[data-toggle="lightbox"]', (e) ->
		e.preventDefault()
		$(@).ekkoLightbox()
		false

	.on 'touchstart', 'img', (e) ->
		e.preventDefault()

	.on 'submit', 'form', ->
		if sessionStorage
			$(@).find('.flash').each ->
				$field = $ @
				sessionStorage[$field.attr('ng-model')] =
					if $field.prop('type') is 'checkbox'
						if $field.prop('checked') then 'on' else 'off'
					else
						$field.val()


$('.flash').each ->
	$field = $ @
	name = $field.attr('ng-model')
	if $field.prop('type') is 'checkbox'
		if sessionStorage[name] is 'on'
			$field.prop 'checked', true
		if sessionStorage[name] is 'off'
			$field.prop 'checked', false
	else
		val = $field.val()
		if !val || !val.length
			$field.val sessionStorage[name]
	delete sessionStorage[name]


onResize = (fct) ->
	$(window).resize fct
	fct.call @


onResize ->
	$('[data-ratio]').each ->
		$block = $ @
		ratio = $block.data('ratio') * 1
		if ratio > 0
			$block.height $block.width() / ratio


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

if (piwikSettings = getData 'piwik')
	_paq = _paq or []
	_paq.push ["trackPageView"]
	_paq.push ["enableLinkTracking"]
	(->
		u = ((if ("https:" is document.location.protocol) then "https" else "http")) + "://" + (piwikSettings.host || 'piwik') + "/"
		_paq.push [
			"setTrackerUrl"
			u + "piwik.php"
		]
		_paq.push [
			"setSiteId"
			(piwikSettings.id || 1)
		]
		d = document
		g = d.createElement("script")
		s = d.getElementsByTagName("script")[0]
		g.type = "text/javascript"
		g.defer = true
		g.async = true
		g.src = u + "piwik.js"
		s.parentNode.insertBefore g, s
		return
	)()

if (googleAnalyticsSettings = getData 'googleAnalytics')
	((w, d, s, u, g, a, m) ->
		w["GoogleAnalyticsObject"] = g
		w[g] = w[g] or ->
			(w[g].q = w[g].q or []).push arguments
			return
		w[g].l = 1 * new Date()
		a = d.createElement(s)
		m = d.getElementsByTagName(s)[0]
		a.async = 1
		a.src = u
		m.parentNode.insertBefore a, m
		return
	) window, document, "script", "//www.google-analytics.com/analytics.js", (googleAnalyticsSettings.callback || "ga")
	ga "create", (googleAnalyticsSettings.id || ""), "auto"
	ga "send", "pageview"