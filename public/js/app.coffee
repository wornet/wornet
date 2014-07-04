Controllers =

	App: ($scope) ->
		$scope.isAngularWorking = "Angular is working"

	Calendar:($scope) ->
		agenda = new Crud '/agenda'
		date = new Date()
		d = date.getDate()
		m = date.getMonth()
		y = date.getFullYear()


		events = getData('events')
		eventsTitles = {}
		for event in events
			if event._id?
				event.id = event._id
			eventsTitles[event.id] = event.title
		$scope.events = events


		getEvent = (event) ->
			data = {}
			for key in 'id title content url start end allDay'.split /\s/g
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


		$scope.alertOnEventClick = (event, allDay, jsEvent, view) ->
			console.log event
			console.log allDay
			console.log jsEvent
			console.log view
			return


		$scope.rename = (event) ->
			if event.title isnt eventsTitles[event.id]
				$scope.saveEvent event, (data) ->
					if typeof(data) is 'object' && typeof(data.err) is 'undefined'
						eventsTitles[event.id] = event.title


		$scope.addRemoveEventSource = (sources, source) ->
			canAdd = false
			angular.forEach sources, (value, key) ->
				if sources[key] is source
					sources.splice key, 1
					canAdd = true

			sources.push source	if canAdd


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
			events = []
			for ev in $scope.events
				if ev.id isnt event.id
					events.push ev
			$scope.events = events
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

				eventClick: ->
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
	get: (url, settings, _method, defaultType) ->
		if typeof(settings) is 'function'
			settings =
				success: settings
		settings.type = settings.type || (defaultType || "GET")
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


class Crud
	constructor: (url) ->
		@baseUrl = url

	url: (url) ->
		new Crud @baseUrl + url

	get: (settings, _method, defaultType) ->
		Ajax.get @baseUrl, settings, _method, defaultType

	post: (settings, _method) ->
		Ajax.post @baseUrl, settings, _method

	put: (settings) ->
		Ajax.put @baseUrl, settings

	delete: (settings) ->
		Ajax.delete @baseUrl, settings


$(document).ajaxComplete (event, xhr, settings) ->
	if settings.type is "POST"
		data = xhr.responseText
		if settings.dataType.toLowerCase() is "json"
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


dateTexts = getData('dateTexts')

calendarGetText = (name) ->
	if typeof(dateTexts[name]) is 'undefined'
		console.warn name + " calendar text not found."
		console.trace()
	dateTexts[name]


lang = $('html').attr 'lang'
shortLang = lang.split(/[^a-zA-Z]/)[0]


Wornet = angular.module 'Wornet', [
	"ui.calendar"
	"ui.bootstrap"
]


for controller, method of Controllers
	Wornet.controller controller + 'Ctrl', ['$scope', method]
