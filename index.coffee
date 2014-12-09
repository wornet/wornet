#!/usr/bin/env coffee

'use strict'

require('./core/system/date')
console['log'] 'Starting Wornet  ' + Date.log()

# Dependancies to load
'kraken-js child_process extend glob express path connect fs mongoose crypto passport stylus imagemagick deep-extend'
.split(/\s+/).forEach (dependancy) ->
	global[dependancy.replace(/([^a-zA-Z0-9_]|js$)/g, '')] = require dependancy

# Get shortcuts from dependancies
'child_process.exec mongoose.Schema'
.split(/\s+/).forEach (shortcut) ->
	shortcut = shortcut.split '.'
	global[shortcut[1]] = global[shortcut[0]][shortcut[1]]

# Available everywhere
extend global,
	extend: extend
	glob: glob
	fs: fs
	path: path


global.app = express()


# Config load
config = require(__dirname + '/core/global/start/config')(app.settings.env, process.env.PORT)
port = config.port


process.on 'uncaughtException', (err) ->
	if err.code is 'EADDRINUSE'
		console['log'] 'Attempt to listen ' + port + ' on ' + app.settings.env + '(' + app.get('env') + ')'
		throw err
	console['warn'] 'Caught exception: ' + err
	console['log'] err.stack || (new Error).stack

options = require('./core/system/options')(app, port)
session = require('express-session')
MemcachedStore = require('connect-memcached')(session)
RedisStore = require('connect-redis')(session)

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

	# Get a memcached client to use cache
	memStore = new MemcachedStore
	global.mem = memStore.client

	# Use redis for sessions
	redisStore = new RedisStore
	global.redis = redisStore.client

	app.use session
		# Express session options
		resave: true,
		saveUninitialized: false,
		secret: "6qed36sQyAurbQCLNE3X6r6bbtSuDEcU"
		key: "w"
		store: redisStore

	# Launch Kraken
	app.use kraken options

	require(__dirname + '/core/global/request/handle-static')(app)

	app.on 'start', ->

		console['log'] 'Wornet is ready  ' + Date.log()
		defer.forEach (done) ->
			done app

		glob __dirname + '/core/global/start/**/*.coffee', (er, files) ->
			files.forEach (file) ->
				require file

	# Handle errors and print in the console
	if config.port is 443

		app.all '*', (req, res, next) ->
			if req.secure
				next()
			else
				res.redirect 'https://' + req.hostname + req.url

		app.listen 80, (err) ->
			if err
				throw err
			else
				console['log'] '[%s] Redirect on http://localhost:%d', app.settings.env, 80

		app.listen 443, (err) ->
			if err
				throw err
			else
				console['log'] '[%s] Listening on http://localhost:%d', app.settings.env, 443
	else
		app.listen port, (err) ->
			if err
				throw err
			else
				console['log'] '[%s] Listening on http://localhost:%d', app.settings.env, port

exports = module.exports = app
