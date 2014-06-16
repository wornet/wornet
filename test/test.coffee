'use strict'

# No conflict if a 8000 port app is running
process.env.PORT = 8001

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


app = require __dirname + '/../index'
agent = request.agent app
#onready = require __dirname + '/../core/system/autoload'

module.exports = (done) ->
	app.onready ->
		done app, agent