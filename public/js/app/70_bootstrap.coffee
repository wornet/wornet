# Get display language
lang = $('html').attr 'lang'
shortLang = lang.split(/[^a-zA-Z]/)[0]

# Load angular and angular modules
Wornet = angular.module 'Wornet', [
	'ui.calendar'
	'ui.bootstrap'
]

# Load controllers
for controller, method of Controllers
	Wornet.controller controller + 'Ctrl', ['$scope', method]
