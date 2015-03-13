'use strict'

onready = require './test'
command = require __dirname + '/../core/system/command.js'

describe "client-side unit tests", ->

	@timeout 5.minutes

	save = {}

	beforeEach (done) ->
		onready.app ->
			MailPackage.exec = (options, done) ->
				html = options.html || options.text || ''
				link = html.match /https?:\/\/[^"'\s]/g
				link = if link then link[0] else null
				# TO DO: Check the link
				console['log'] [html, link]
				done()
			done()

	xit "must pass all the tests", (done) ->

	 	url = 'http://localhost:' + process.env.PORT + '/test'

	 	exec = require("child_process").exec
	 	child = exec __dirname + '/../node_modules/phantomjs/bin/phantomjs ' + __dirname + '/phantomjs/client.js'
	 	child.on 'data', (data) ->
	 		data.should.equal "Wornet"
	 		done()

		# global.clitentSideUnitTestsCallback = (data) ->
		# 	delay 1, ->
		# 		totalSpecsDefined = intval data.totalSpecsDefined
		# 		specsExecuted = intval data.specsExecuted
		# 		failureCount = intval data.failureCount
		# 		successCount = intval data.successCount
		# 		totalSpecsDefined.should.be.above 1 # Several specs must be defined
		# 		specsExecuted.should.equal totalSpecsDefined # All the specs must be executed
		# 		failureCount.should.equal 0 # No tests must fail
		# 		successCount.should.equal specsExecuted # All the tests must succeed
		# 		done()

		# command.open url
