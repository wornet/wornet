# Get display language
lang = $('html').attr 'lang'
shortLang = lang.split(/[^a-zA-Z]/)[0]

# Load angular and angular modules
Wornet = angular.module 'Wornet', [
	'ui.calendar'
	'ui.bootstrap'
]

#Angular Wornet services
.factory 'chatService', ['$rootScope', ($rootScope) ->
	window.chatService =
		chatWith: (user, message) ->
			$rootScope.$broadcast 'chatWith', user, message
			return
	chatService
]

.factory 'statusService', ['$rootScope', ($rootScope) ->
	window.statusService =
		receiveStatus: (status) ->
			$rootScope.$broadcast 'receiveStatus', status
			return
	statusService
]

#Angular Wornet directives
.directive 'focus', ->
	['$timeout', ($timeout) ->
		scope:
			trigger: '@focus'
		link: ['$scope', '$element', ($scope, $element) ->
			$scope.$watch 'trigger', (value) ->
				if value is "true"
					$timeout ->
						$element[0].focus()
						return
				return
			return
		]
	]

.filter 'urlencode', ->
	window.encodeURIComponent

ControllersByService =
	chatService: 'Profile Chat'
	statusService: 'Status'

# Load controllers
for controller, method of Controllers
	params = ['$scope']
	for service, controllers of ControllersByService
		if controllers.split(/\s+/g).indexOf(controller) isnt -1
			params.push service
	params.push method
	Wornet.controller controller + 'Ctrl', params
