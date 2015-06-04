'use strict'

views =
	sum: 0
	methods: {}
	pages: {}

StatisticsPackage =
	saveInterval: regularTask 10.minutes, ->

	track: (method, url, isXHR) ->
		page = method + ':' + url
		views.sum++
		views.method[method] ||= 0
		views.method[method]++
		views.pages[page] ||= 0
		views.pages[page]++

module.exports = StatisticsPackage
