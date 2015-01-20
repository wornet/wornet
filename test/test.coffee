'use strict'

# No conflict if a 8000 port app is running
process.env.PORT = 8001
rootRequire = (file) ->
	require __dirname + '/../' + file
rootRequire 'core/global/start/bootstrap'

request = require 'supertest'
chai = require 'chai'
chai.should()

extend global,
	assert: require 'assert'
	chai: chai
	expect: chai.expect

module.exports =
	utils: (done) ->
		autoload = rootRequire 'core/system/autoload'
		autoload ->
			done()

	app: (done) ->
		app = rootRequire 'index'
		agent = request.agent app
		app.onready ->
			done app, agent
