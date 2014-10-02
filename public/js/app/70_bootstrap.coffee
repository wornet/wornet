# Get display language
lang = $('html').attr 'lang'
shortLang = lang.split(/[^a-zA-Z]/)[0]

# Load angular and angular modules
Wornet = angular.module 'Wornet', [
	'ui.calendar'
	'ui.bootstrap'
]

#Angular Wornet services
Wornet.factory 'chatService', ($rootScope) ->
	window.chatService =
		chatWith: (user, message) ->
			console.log 'service'
			console.log message
			$rootScope.$broadcast 'chatWith', user, message
	chatService

# Load controllers
for controller, method of Controllers
	params = ['$scope']
	if (['Profile', 'Chat']).indexOf(controller) isnt -1
		params.push 'chatService'
	params.push method
	Wornet.controller controller + 'Ctrl', params
