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
		clear: (users) ->
			$rootScope.$broadcast 'clear', users
			return
		updateNewMessages: (userIds, nbOfNewMessages) ->
			$rootScope.$broadcast 'updateNewMessages', userIds, nbOfNewMessages
			return
		changePageTitle: (newChatMessages) ->
			$rootScope.$broadcast 'changePageTitle', newChatMessages
			return
	chatService
]

.factory 'statusService', ['$rootScope', ($rootScope) ->
	window.statusService =
		receiveStatus: (status) ->
			$rootScope.$broadcast 'receiveStatus', status
			return
		receiveComment: (comment) ->
			$rootScope.$broadcast 'receiveComment', comment
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

.factory 'smiliesService', ['$rootScope', ($rootScope) ->
	enableSmilies = false
	smilies =
		happy: [":)", ":-)"]
		sad: [":(", ":-("]
		lol: [":D", ":-D"]
		blink: [";)", ";-)"]
		joke: [":P", ":-P", ":p", ":-p"]
		surprise: [":O", ":-O", ":o", ":-o", "o_O", "O_O", "O_o"]
		blush: [":$", ":-$"]
		love: ["*_*"]
		cry: [":'("]
		heart: ["<3", "&lt;3"]
	filter: (text, safe = false) ->
		unless safe
			text = safeHtml text
		for className, codes of smilies
			pattern = codes.map(regExpEscape).join '|'
			regExp = new RegExp pattern, 'g'
			text = text.replace regExp, (code) ->
				unless enableSmilies
					enableSmilies = true
					$rootScope.$broadcast 'enableSmilies', true
				'<i class="' + className + '">' + code + '</i>'
		text
]

#Angular Wornet directives
.directive 'focus', ['$timeout', ($timeout) ->
	scope:
		trigger: '@focus'
	link: ($scope, $element) ->
		$scope.$watch 'trigger', (value) ->
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

.directive 'langTemplate', ->
	scope: {}
	template: '<div ng-include="\'/template/\' + template + \'/\' + lang" ng-if="loaded"></div>'
	link: ($scope, $element, $attributes) ->
		$scope.lang = $('html').prop 'lang'
		$scope.template = $attributes.langTemplate
		$scope.loaded = false
		$element.parents('.modal:first').on 'show.bs.modal', ->
			$scope.$apply ->
				$scope.loaded = true
				return
			return
		return

.directive 'nonBlockClick', ['$timeout', ($timeout) ->
	link: ($scope, $element, $attributes) ->
		$element.on 'touchtap click', ->
			href = $element.attr 'href'
			ajax = $element.hasClass 'ajax'
			$element.removeAttr 'href'
			$element.removeClass 'ajax'
			$timeout ->
				if href
					$element.prop 'href', href
				if ajax
					$element.addClass 'ajax'
				$scope.$eval $attributes.nonBlockClick
				return
			return
		return
]

.directive 'scrollDetect', ->
	link: ($scope, $element, $attributes) ->
		getOffset = ->
			$scope.$eval $attributes.offset
		callback = $scope.$eval $attributes.callback
		gap = $scope.$eval $attributes.gap
		$scrollable = if $attributes.scrollable
			$ $attributes.scrollable
		else
			$document
		lock = false
		$scrollable.scroll ->
			scrollTopMax = $scrollable[0].scrollHeight
			if 'undefined' is typeof scrollBottom
				scrollTopMax = document.body.scrollHeight - document.body.offsetHeight
			else
				scrollTopMax -= $scrollable[0].offsetHeight

			if $scrollable.scrollTop() > (scrollTopMax - gap) and offset = getOffset()
				data = {}
				if offset
					data.offset = offset
				if ! lock and $scope.$eval $attributes.verifyToLoad
					lock = true
					url = $scope.$eval $attributes.url
					$element.addClass 'loading'
					Ajax.post url,
						data: data
						success: (data) ->
							$element.removeClass 'loading'
							callback offset, data
							return
					.always ->
						lock = false
		return

.filter 'urlencode', ->
	window.encodeURIComponent

.filter 'lastest', ->
	lastest

.filter 'smilies', ['smiliesService', '$sce', (smiliesService, $sce) ->
	(text) ->
		$sce.trustAsHtml smiliesService.filter text
]

ControllersByService =
	notificationsService: 'Notifications'
	chatService: 'Profile'
	smiliesService: 'Status'
	statusService: 'Status'
	$sce: 'Notifications'
	$http: 'Event'

# Load controllers
for controller, method of Controllers
	params = ['$scope']
	for service, controllers of ControllersByService
		if controllers.split(/\s+/g).indexOf(controller) isnt -1
			params.push service
	params.push method
	Wornet.controller controller + 'Ctrl', params

countLoaders()
