Controllers =

	App: ($scope) ->
		$scope.isAngularWorking = "Angular is working"

	Calendar:($scope) ->
		date = new Date()
		d = date.getDate()
		m = date.getMonth()
		y = date.getFullYear()
		$scope.changeTo = "Hungarian"
		
		# event source that pulls from google.com 
		$scope.eventSource =
			url: "http://www.google.com/calendar/feeds/usa_en%40holiday.calendar.google.com/public/basic"
			className: "gcal-event" # an option!
			currentTimezone: data('timezone') # an option!

		
		# event source that contains custom events on the scope 
		$scope.events = data('events')
		
		# event source that calls a function on every view switch 
		$scope.eventsF = (start, end, callback) ->
			s = new Date(start).getTime() / 1000
			e = new Date(end).getTime() / 1000
			m = new Date(start).getMonth()
			events = [
				title: "Feed Me " + m
				start: s + (50000)
				end: s + (100000)
				allDay: false
				className: ["customFeed"]
			]
			callback events
			return

		$scope.calEventsExt =
			color: "#f00"
			textColor: "yellow"
			events: [
				{
					type: "party"
					title: "Lunch"
					start: new Date(y, m, d, 12, 0)
					end: new Date(y, m, d, 14, 0)
					allDay: false
				}
				{
					type: "party"
					title: "Lunch 2"
					start: new Date(y, m, d, 12, 0)
					end: new Date(y, m, d, 14, 0)
					allDay: false
				}
				{
					type: "party"
					title: "Click for Google"
					start: new Date(y, m, 28)
					end: new Date(y, m, 29)
					url: "http://google.com/"
				}
			]

		
		# alert on eventClick 
		$scope.alertOnEventClick = (event, allDay, jsEvent, view) ->
			$scope.alertMessage = (event.title + " was clicked ")
			return

		
		# alert on Drop 
		$scope.alertOnDrop = (event, dayDelta, minuteDelta, allDay, revertFunc, jsEvent, ui, view) ->
			$scope.alertMessage = ("Event Droped to make dayDelta " + dayDelta)
			return

		
		# alert on Resize 
		$scope.alertOnResize = (event, dayDelta, minuteDelta, revertFunc, jsEvent, ui, view) ->
			$scope.alertMessage = ("Event Resized to make dayDelta " + minuteDelta)
			return

		
		# add and removes an event source of choice 
		$scope.addRemoveEventSource = (sources, source) ->
			canAdd = 0
			angular.forEach sources, (value, key) ->
				if sources[key] is source
					sources.splice key, 1
					canAdd = 1
				return

			sources.push source	if canAdd is 0
			return

		
		# add custom event
		$scope.addEvent = ->
			$scope.events.push
				title: "Open Sesame"
				start: new Date(y, m, 28)
				end: new Date(y, m, 29)
				className: ["openSesame"]

			return

		
		# remove event 
		$scope.remove = (index) ->
			$scope.events.splice index, 1
			return

		
		# Change View 
		$scope.changeView = (view, calendar) ->
			calendar.fullCalendar "changeView", view
			return

		
		# Change View 
		$scope.renderCalender = (calendar) ->
			calendar.fullCalendar "render"
			return

		
		# config object 
		$scope.uiConfig = calendar:
			height: 450
			editable: true
			header:
				left: "title"
				center: ""
				right: "today prev,next"

			eventClick: $scope.alertOnEventClick
			eventDrop: $scope.alertOnDrop
			eventResize: $scope.alertOnResize

		$scope.changeLang = ->
			if $scope.changeTo is "Hungarian"
				$scope.uiConfig.calendar.dayNames = [
					"Vasárnap"
					"Hétfő"
					"Kedd"
					"Szerda"
					"Csütörtök"
					"Péntek"
					"Szombat"
				]
				$scope.uiConfig.calendar.dayNamesShort = [
					"Vas"
					"Hét"
					"Kedd"
					"Sze"
					"Csüt"
					"Pén"
					"Szo"
				]
				$scope.changeTo = "English"
			else
				$scope.uiConfig.calendar.dayNames = [
					"Sunday"
					"Monday"
					"Tuesday"
					"Wednesday"
					"Thursday"
					"Friday"
					"Saturday"
				]
				$scope.uiConfig.calendar.dayNamesShort = [
					"Sun"
					"Mon"
					"Tue"
					"Wed"
					"Thu"
					"Fri"
					"Sat"
				]
				$scope.changeTo = "Hungarian"
			return

		
		# event sources array
		$scope.eventSources = [
			$scope.events
			$scope.eventSource
			$scope.eventsF
		]
		$scope.eventSources2 = [
			$scope.calEventsExt
			$scope.eventsF
			$scope.events
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
	name = name.replace(/(\\|")/g, '\\$1')
	objectResolve $('[data-data][data-name="' + name + '"]').data('value')

Wornet = angular.module 'Wornet', [
	"ui.calendar"
	"ui.bootstrap"
]

for controller, method of Controllers
	Wornet.controller controller + 'Ctrl', ['$scope', method]
