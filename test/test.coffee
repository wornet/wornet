'use strict'

# No conflict if a 8000 port app is running
process.env.PORT = 8001
global.config = require(__dirname + '/../core/global/start/config')('production', process.env.PORT)

request = require 'supertest'
chai = require 'chai'
chai.should()

require('extend') global,
	kraken: require 'kraken-js'
	express: require 'express'
	assert: require 'assert'
	glob: require 'glob'
	chai: chai
	expect: chai.expect

module.exports =
	utils: (done) ->
		autoload = require __dirname + '/../core/system/autoload'
		autoload ->
			done()
	,
	app: (done) ->
		app = require __dirname + '/../index'
		agent = request.agent app
		app.onready ->
			done app, agent
