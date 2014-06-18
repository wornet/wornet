Controllers =
	App: ($scope) ->
		$scope.isAngularWorking = "Angular is working"


Wornet = angular.module 'Wornet', []

for controller, method of Controllers
	Wornet.controller controller + 'Ctrl', ['$scope', method]
