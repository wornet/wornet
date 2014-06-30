Controllers =

	App: ($scope) ->
		$scope.isAngularWorking = "Angular is working"

	Calendar:($scope) ->
		date = new Date()
		d = date.getDate()
		m = date.getMonth()
		y = date.getFullYear()


		# event source that pulls from google.com
		# $scope.eventSource =
		# 	url: "http://www.google.com/calendar/feeds/usa_en%40holiday.calendar.google.com/public/basic"
		# 	className: "gcal-event"
		# 	currentTimezone: data('timezone')


		# event source that contains custom events on the scope
		events = data('events')
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
			data


		saveDelays = {}
		saveEvent = (event, cb) ->
			if saveDelays[event.id]?
				clearTimeout saveDelays[event.id]
			saveDelays[event.id] = delay 500, ->
				post '/agenda/edit',
					data:
						event: getEvent event
					success: (data) ->
						delete saveDelays[event.id]
						if cb?
							cb(data)


		# event source that calls a function on every view switch
		# $scope.eventsF = (start, end, callback) ->
		# 	s = new Date(start).getTime() / 1000
		# 	e = new Date(end).getTime() / 1000
		# 	m = new Date(start).getMonth()
		# 	events = [
		# 		title: "Feed Me " + m
		# 		start: s + (50000)
		# 		end: s + (100000)
		# 		allDay: false
		# 		className: ["customFeed"]
		# 	]
		# 	callback events
		# 	return


		$scope.alertOnEventClick = (event, allDay, jsEvent, view) ->
			console.log event
			console.log allDay
			console.log jsEvent
			console.log view
			return


		$scope.alertOnDrop = (event, dayDelta, minuteDelta, allDay, revertFunc, jsEvent, ui, view) ->
			saveEvent event
			return


		$scope.alertOnResize = (event, dayDelta, minuteDelta, revertFunc, jsEvent, ui, view) ->
			saveEvent event
			return


		$scope.rename = (event) ->
			if event.title isnt eventsTitles[event.id]
				saveEvent event, (data) ->
					if typeof(data) is 'object' && typeof(data.err) is 'undefined'
						event.title = eventsTitles[event.id]
			return


		$scope.addRemoveEventSource = (sources, source) ->
			canAdd = false
			angular.forEach sources, (value, key) ->
				if sources[key] is source
					sources.splice key, 1
					canAdd = true
				return

			sources.push source	if canAdd
			return


		$scope.addEvent = ->
			event =
				title: ""
				start: new Date(y, m, d + 1)
				end: new Date(y, m, d + 2)
			$scope.events.push event
			post '/agenda/add',
				data:
					event: getEvent event
				success: (data) ->
					event.id = data._id
			delay 50, ->
				$('ul.events input[ng-model="e.title"]:last').focus()

			return


		$scope.remove = (index) ->
			$scope.events.splice index, 1
			post '/agenda/remove',
				data:
					event: getEvent event
			return


		$scope.changeView = (view, calendar) ->
			calendar.fullCalendar "changeView", view
			return


		$scope.renderCalender = (calendar) ->
			calendar.fullCalendar "render"
			return


		$scope.uiConfig = calendar: $.extend(
			{
				lang: "fr"
				height: 450
				editable: true
				header:
					left: "title"
					center: ""
					right: "today prev,next"

				eventClick: $scope.alertOnEventClick
				eventDrop: $scope.alertOnDrop
				eventResize: $scope.alertOnResize
			}
			dateTexts
		)


		$scope.eventSources = [
			$scope.events
			#$scope.eventSource
			#$scope.eventsF
		]
		return


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


data = (name) ->
	name = name.replace /(\\|")/g, '\\$1'
	$data = $ '[data-data][data-name="' + name + '"]'
	unless $data.length
		console.warn name + " data not found."
		console.trace()
	objectResolve $data.data 'value'


delay = (ms, cb) ->
	setTimeout cb, ms


post = (url, settings) ->
	if typeof(settings) is 'function'
		settings =
			success: settings
	settings.type = settings.type || "POST"
	settings.dataType = settings.dataType || "json"
	settings.data = settings.data || {}
	settings.data._csrf = settings.data._csrf || $('head meta[name="_csrf"]').attr 'content'
	$.ajax url, settings
	# .complete (data) ->
	# 	$('meta[name="_csrf"]').attr('content')


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


dateTexts = data('dateTexts')

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
