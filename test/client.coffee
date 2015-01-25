'use strict'

onready = require './test'
command = require __dirname + '/../core/system/command.js'

describe "client-side unit tests", ->

	@timeout 5.minutes

	save = {}

	beforeEach (done) ->
		global.muteLog = true
		for k, v of console
			save[k] = v
			console[k] = ->
		onready.app ->
			MailPackage.exec = (options, done) ->
				html = options.html || options.text || ''
				link = html.match /https?:\/\/[^"'\s]/g
				link = if link then link[0] else null
				console.log [html, link]
				done()
			done()

	it "must pass all the tests", (done) ->
		url = 'http://localhost:' + process.env.PORT + '/test'

		global.clitentSideUnitTestsCallback = (data) ->
			delay 1, ->
				delete global.muteLog
				for k, v of save
					console[k] = v
				totalSpecsDefined = intval data.totalSpecsDefined
				specsExecuted = intval data.specsExecuted
				failureCount = intval data.failureCount
				successCount = intval data.successCount
				totalSpecsDefined.should.be.above 1 # Several specs must be defined
				specsExecuted.should.equal totalSpecsDefined # All the specs must be executed
				failureCount.should.equal 0 # No tests must fail
				successCount.should.equal specsExecuted # All the tests must succeed
				done()

		command.open url
