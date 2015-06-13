# Get display language
lang = $('html').attr 'lang'
shortLang = lang.split(/[^a-zA-Z]/)[0]

# Load angular and angular modules
Wornet = angular.module 'Wornet', [
	'ui.calendar'
	'ui.bootstrap'
	'ngSanitize'
]

.config ($sceDelegateProvider) ->
	$sceDelegateProvider.resourceUrlWhitelist [
		'self'
		'http://www.youtube.com/embed/**'
		'https://www.youtube.com/embed/**'
		'http://www.dailymotion.com/embed/video/**'
		'https://www.dailymotion.com/embed/video/**'
	]

#Angular Wornet services
.factory 'chatService', ['$rootScope', ($rootScope) ->
	window.chatService =
		chatWith: (user, message) ->
			$rootScope.$broadcast 'chatWith', user, message
			return
		all: (messages) ->
			$rootScope.$broadcast 'all', messages
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

.factory 'notificationsService', ['$rootScope', ($rootScope) ->
	window.notificationsService =
		receiveNotification: (notification) ->
			$rootScope.$broadcast 'receiveNotification', notification
		setNotifications: (notifications) ->
			$rootScope.$broadcast 'setNotifications', notifications
			return
	notificationsService
]

#Angular Wornet directives
.directive 'focus', ->
	['$timeout', ($timeout) ->
		scope:
			trigger: '@focus'
		link: ($scope, $element) ->
			$scope.$watch 'trigger', (value) ->
				if value is "true"
					$timeout ->
						$element[0].focus()
						return
				return
			return
	]

.directive 'pill', ->
	scope: true
	link: ($scope, $element) ->
		refreshPillOfList $element[0]
		return

.filter 'urlencode', ->
	window.encodeURIComponent

.filter 'lastest', ->
	lastest

ControllersByService =
	notificationsService: 'Notifications'
	chatService: 'Profile'
	statusService: 'Status'
	$sce: 'Notifications Chat'

# Load controllers
for controller, method of Controllers
	params = ['$scope']
	for service, controllers of ControllersByService
		if controllers.split(/\s+/g).indexOf(controller) isnt -1
			params.push service
	params.push method
	Wornet.controller controller + 'Ctrl', params

countLoaders()
