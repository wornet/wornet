Controllers =

	Login: ($scope) ->
		$scope.submit = (user) ->
			Ajax.post '/user/login',
				data: user
				success: (data) ->
					if data.goingTo
						location.href = data.goingTo
					else
						errors = data.err || "Erreur"
						if typeof(errors) isnt 'object'
							errors = [errors]
						$errors = $('#loginErrors').html('')
						for error in errors
							$errors.append('<div class="alert alert-danger">' + error + '</div>')
						$errors.slideUp(0).slideDown('fast')

	# Signin: ($scope) ->
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
		agenda = new Crud '/agenda'
		date = new Date()
		d = date.getDate()
		m = date.getMonth()
		y = date.getFullYear()


		events = getData 'events'
		eventsTitles = {}
		for event in events
			if event._id?
				event.id = event._id
			eventsTitles[event.id] = event.title
		$scope.events = events


		getEvent = (event) ->
			data = {}
			for key in 'id user title content url start end allDay'.split /\s/g
				if event[key]?
					data[key] = event[key]
					if data[key] instanceof Date
						data[key] = (new Date(data[key].getTime() - (data[key].getTimezoneOffset() * 60000))).toISOString()
			data


		saveDelays = {}
		$scope.saveEvent = (event, cb) ->
			if saveDelays[event.id]?
				clearTimeout saveDelays[event.id]
			saveDelays[event.id] = delay 500, ->
				agenda.post
					data:
						event: getEvent event
					success: (data) ->
						delete saveDelays[event.id]
						if cb?
							cb(data)


		$scope.editContent = (event, allDay, jsEvent, view) ->
			$scope.eventToEdit = $.extend {}, event
			$('#eventContent').modal()


		$scope.saveContent = (event, allDay, jsEvent, view) ->
			for ev, index in $scope.events
				if ev.id is event.id
					ev.content = event.content
					$scope.saveEvent ev
					break


		$scope.rename = (event) ->
			if event.title isnt eventsTitles[event.id]
				$scope.saveEvent event, (data) ->
					if typeof(data) is 'object' && typeof(data.err) is 'undefined'
						eventsTitles[event.id] = event.title


		$scope.addEvent = ->
			start = new Date(y, m, d + 1)
			start.setHours(14)
			end = new Date(y, m, d + 1)
			end.setHours(16)
			event =
				title: ""
				start: start
				end: end
				allDay: false
			$scope.events.push event
			agenda.put
				data:
					event: getEvent event
				success: (data) ->
					event.id = data._id
			delay 50, ->
				$('ul.events input[ng-model="e.title"]:last').focus()


		$scope.remove = (event) ->
			for ev, index in $scope.events
				if ev.id is event.id
					$scope.events.splice index, 1
					break
			agenda.delete
				data:
					event: getEvent event


		$scope.changeView = (view, calendar) ->
			calendar.fullCalendar "changeView", view


		$scope.renderCalender = (calendar) ->
			calendar.fullCalendar "render"


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


		$scope.eventSources = [$scope.events]


objectResolve = (value) ->

	key = 'resolvedCTBSWSydrqSuW2QyzUGMBTshU9SCJn5p'

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

	leave = (value) ->
		key = 'resolvedCTBSWSydrqSuW2QyzUGMBTshU9SCJn5p'
		switch typeof(value)
			when 'object'
				if value[key]
					delete value[key]
					for v, i in value
						value[i] = leave value[i]
		value

	leave enter value


getData = (name) ->
	name = name.replace /(\\|")/g, '\\$1'
	$data = $ '[data-data][data-name="' + name + '"]'
	unless $data.length
		console.warn name + " data not found."
		console.trace()
	objectResolve $data.data 'value'


delay = (ms, cb) ->
	setTimeout cb, ms


Ajax =
	get: (url, settings, _method, defaultType = "GET") ->
		if typeof(settings) is 'function'
			settings =
				success: settings
		settings.type = settings.type || defaultType
		settings.dataType = settings.dataType || "json"
		settings.data = settings.data || {}
		settings.data._csrf = settings.data._csrf || $('head meta[name="_csrf"]').attr 'content'
		if _method?
			settings.data._method = _method
		$.ajax url, settings

	post: (url, settings, _method) ->
		@get url, settings, _method, "POST"

	put: (url, settings) ->
		@post url, settings, "PUT"

	delete: (url, settings) ->
		@post url, settings, "DELETE"

	contentSelector: '[role="main"]'
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


$page = $ Ajax.contentSelector


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


$.fn.readyToFade = ->
	if @.css('opacity') is '0'
		@.css('opacity', '1').fadeOut(0)
	@


$(document)
	.ajaxComplete (event, xhr, settings) ->
		if settings.type is "POST"
			data = xhr.responseText
			if settings.dataType? && settings.dataType.toLowerCase() is "json"
				data = $.parseJSON data
				if typeof(data) isnt 'object'
					console.warn 'JSON data response is not an object'
					console.trace()
				else if typeof(data.err) isnt 'undefined'
					err = data.err
				_csrf = data._csrf
			else
				_csrf = $(data).find('meta[name="_csrf"]').attr 'content'
		$('head meta[name="_csrf"]').attr 'content', _csrf
		throw err if err?

	.on 'focus', '.form-control', ->
		$(@).prev('.tooltip').readyToFade().fadeIn('fast')

	.on 'blur', '.form-control', ->
		$(@).prev('.tooltip').fadeOut('fast')

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
	'ngRoute'
]


for controller, method of Controllers
	Wornet.controller controller + 'Ctrl', ['$scope', '$route', method]
