'use strict'

do ->

	global.coreDir = __dirname + '/../../'
	global.rootDir = coreDir + '../'
	require coreDir + 'system/date'
	console['log'] 'Starting Wornet  ' + (new Date).log()

	# Dependancies to load
	'kraken-js child_process extend glob express path connect fs mongoose crypto passport stylus imagemagick deep-extend ua-parser-js'
	.split(/\s+/).forEach (dependancy) ->
		global[dependancy.replace(/([^a-zA-Z0-9_]|js$)/g, '')] = require dependancy

	# Get shortcuts from dependancies
	'child_process.exec mongoose.Schema'
	.split(/\s+/).forEach (shortcut) ->
		shortcut = shortcut.split '.'
		global[shortcut[1]] = global[shortcut[0]][shortcut[1]]


	global.app = express()

	session = require 'express-session'

	# Get functions
	extend global, require coreDir + 'utils/functions'
	extend global,
		# Store engines
		MemcachedStore: require('connect-memcached') session
		RedisStore: require('connect-redis') session

	# Config load
	global.config = require(coreDir + 'global/start/config') app.settings.env, process.env.PORT
	port = config.port

	# Set application options
	global.options = require(coreDir + 'system/options') app, port

	unless global.stopCatchException
		process.on 'uncaughtException', (err) ->
			if err.code is 'EADDRINUSE'
				console['log'] 'Attempt to listen ' + port + ' on ' + app.settings.env + '(' + app.get('env') + ')'
				throw err
			prefix = 'Caught exception: '
			if err.message
				err.message = prefix + err.message
			else
				err = prefix + err
			warn err, false
			if global.GitlabPackage
				GitlabPackage.issue err
			else
				throw err
