'use strict'

# Dependancies to load
kraken = require 'kraken-js'
extend = require 'extend'
glob = require 'glob'
express = require 'express'
path = require 'path'
connect = require 'connect'
fs = require 'fs'
exec = require('child_process').exec

# Available everywhere
extend global,
	extend: extend
	glob: glob
	fs: fs
	path: path

app = express()

# Config load
config = {}

port = process.env.PORT || 8000

options = (require './core/system/options')(port)

# Build coffee scripts
exec 'coffee -b -o .build/js -wc public/js'

# Make config usables everywhere
extend global,
	config: config,
	options: options

defer = []
app.onready = (done) ->
	defer.push done

# Load all files contained in autoloadDirectories
onready = require './core/system/autoload'
onready ->

	# When no more directory need to be loaded

	# Make functions and config usables in views
	extend app.locals, functions
	extend app.locals,
		config: config
		options: options

	# Launch Kraken
	app.use kraken options

	app.on 'start', ->
		console.log 'Wornet is ready'
		defer.forEach (done) ->
			done app

	# Handle errors and print in the console
	app.listen port, (err) ->
		console.log '[%s] Listening on http://localhost:%d', app.settings.env, port

exports = module.exports = app