'use strict'

views =
	sum: 0
	methods: {}
	pages: {}

StatisticsPackage =
	saveInterval: if config.wornet.trackers.server
		regularTask 10.minutes, ->

	track: (method, url, isXHR) ->
		if config.wornet.trackers.server
			page = method + ':' + url
			views.sum++
			views.methods[method] ||= 0
			views.methods[method]++
			views.pages[page] ||= 0
			views.pages[page]++

module.exports = StatisticsPackage
