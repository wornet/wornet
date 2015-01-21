'use strict'

onready = require './test'
command = require __dirname + '/../core/system/command.js'
isProbablyUnix = __dirname.charAt(0) is '/'

describe "client-side unit tests", ->

	@timeout 1.minute

	save = {}

	beforeEach (done) ->
		global.muteLog = true
		for k, v of console
			save[k] = v
			console[k] = ->
		onready.app ->
			done()

	it "must pass all the tests", (done) ->
		url = 'http://localhost:' + process.env.PORT + '/test'
		program = if isProbablyUnix then 'xdg-open' else 'start'

		global.clitentSideUnitTestsCallback = (data) ->
			delay 1, ->
				delete global.muteLog
				for k, v of save
					console[k] = v
				totalSpecsDefined = intval data.totalSpecsDefined
				specsExecuted = intval data.specsExecuted
				failureCount = intval data.failureCount
				successCount = intval data.successCount
				totalSpecsDefined.should.be.above 1
				specsExecuted.should.be.above 1
				specsExecuted.should.equal totalSpecsDefined
				failureCount.should.equal 0
				successCount.should.equal specsExecuted
				done()

		command program + ' ' + url
