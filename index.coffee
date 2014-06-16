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

options =
	onconfig: (localConfig, next) ->
		extend config, localConfig._store
		if config.env.development
			(['config', 'hooks/post-receive', 'hooks/post-receive.bat', 'hooks/pre-commit', 'hooks/pre-commit.bat']).forEach (file) ->
				copy 'setup/git/' + file, '.git/' + file
				console.log 'setup/git/' + file + ' >>> .git/' + file
		next null, localConfig

port = process.env.PORT || 8000

# Build coffee scripts
exec 'coffee -b -o .build/js -wc public/js'

# Get functions
functions = require './core/utils/functions'

# Make functions and config usables in controllers and other stuff
extend global, functions
extend global,
	config: config

# Make functions and config usables in views
extend app.locals, functions
extend app.locals,
	config: config

defer = []
app.onready = (done) ->
	defer.push done

# Load all files contained in autoloadDirectories
onready = require './core/system/autoload'
onready ->

	# When no more directory need to be loaded

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