#!/usr/bin/env coffee

'use strict'

require('./core/system/date')
console.log 'Starting Wornet  ' + Date.log()

# Dependancies to load
'kraken-js child_process extend glob express path connect fs mongoose crypto passport stylus imagemagick'
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
config = {}

port = process.env.PORT || 8000

process.on 'uncaughtException', (err) ->
	console.warn 'Caught exception: ' + err
	console.log err.stack

options = require('./core/system/options')(port)
methodOverride = require('method-override')()
bodyParser = require('body-parser')()
flash = require('connect-flash')
cookieParser = require('cookie-parser')
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
		secret: "6qed36sQyAurbQCLNE3X6r6bbtSuDEcU"
		key: "w"
		store: redisStore

	# Before each request
	app.use (req, res, done) ->

		res.setTimeLimit config.wornet.timeout
		res.on 'finish', ->
			clearTimeout res.excedeedTimeout

		if req.connection.remoteAddress is '127.0.0.1'
			switch req.url
				when '/status'
					return res.end 'OK'

		next = ->
			# Parse body from requests
			bodyParser req, res, ->
				# Available PUT and DELETE on old browsers
				methodOverride req, res, done
				# To simulate a slow bandwith add a delay like this :
				# methodOverride req, res, ->
				#	delay 3000, done

		if /^\/((img|js|css|fonts|components)\/|favicon\.ico)/.test req.originalUrl
			req.isStatic = true
			req.url = req.url.replace /\?.*$/g, ''
			ie = req.headers['user-agent'].match(/MSIE[\\/\s]([0-9\.]+)/g)
			if ie
				ie = intval ie.substr(5)
			else
				ie = 0
			req.ie = ie
			methods =
				js: uglifyJs
				css: (str) ->
					str.replace /[\r\n\t]/g, ''
			###
			In production mode, all scripts are minified with UglifyJS and joined in /js/all.js
			And all styles are minified with deleting \r, \n and \t and joined in /css/all.css
			###
			for lang, method of methods
				if (req._parseUrl || {}).pathname || req.url is '/' + lang + '/all.' + lang
					file = __dirname + '/.build/' + lang + '/all-ie-' + req.ie + '.' + lang
					fs.readFile file, ((method, list) ->
						(err, content) ->
							if err
								concatCallback '', list, method, (content) ->
									res.end content
									fs.writeFile file, content
								,
									ie: req.ie
							else
								res.end content
					)(method, options['main' + ucfirst(lang)]())
					return
			if req.url.indexOf('/img/photo/') is 0
				req.url = req.url.replace /^(\/img\/photo\/[^\/]+)\/[^\/]+\.jpg$/g, '$1.jpg'
			else if req.url.indexOf('/fonts/glyphicons') is 0
				req.url = '/components/bootstrap' + req.url
			done()
		else
			# Load all scripts in core/global/request directory
			# Not yet needed
			# glob __dirname + "/core/global/request/**/*.coffee", (er, files) ->
			# 	pendingFiles = files.length
			# 	if pendingFiles
			# 		files.forEach (file) ->
			# 			value = require file
			# 			if typeof(value) is 'function'
			# 				value req, res, ->
			# 					unless --pendingFiles
			# 						next()
			# 			else
			# 				unless --pendingFiles
			# 					next()
			# 	else
			# 		next()
			next()

	# Launch Kraken
	app.use kraken options

	app.on 'start', ->

		console.log 'Wornet is ready  ' + Date.log()
		defer.forEach (done) ->
			done app

		glob __dirname + "/core/global/start/**/*.coffee", (er, files) ->
			files.forEach (file) ->
				require file

	app.on 'middleware:after:session', (eventargs) ->
		# Flash session (store data in sessions to the next page only)
		app.use flash()
		# Check if user is authentificated and is allowed to access the requested URL
		app.use auth.isAuthenticated
		# Allow to set and get cookies in routes methods
		secret = 'kjsqdJL7KSU9DEU78_Zjsq0KJD23LKSQ_lkjdzij1sqodqZE325dZDKJP-QD'
		app.use cookieParser(secret)
		# Store sessions in Memcached
		###
		app.use(session(
			secret: config.session.module.arguments[0].secret
			key: config.session.module.arguments[0].key
			store: new MemcachedStore
				hosts: ['127.0.0.1:11211']
		))
		###

	# Handle errors and print in the console
	app.listen port, (err) ->
		console.log '[%s] Listening on http://localhost:%d', app.settings.env, port

exports = module.exports = app
