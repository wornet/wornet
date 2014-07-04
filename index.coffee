'use strict'

# Dependancies to load
'kraken-js child_process extend glob express path connect fs mongoose crypto passport'.split(/\s+/).forEach (dependancy) ->
	global[dependancy.replace(/([^a-zA-Z0-9_]|js$)/g, '')] = require dependancy

# Get shortcuts from dependancies
'child_process.exec mongoose.Schema'.split(/\s+/).forEach (shortcut) ->
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

options = (require './core/system/options')(port)
methodOverride = (require 'method-override')()
bodyParser = (require 'body-parser')()

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

	# Before each request
	app.use (req, res, done) ->

		next = ->
			# Parse body from requests
			bodyParser req, res, ->
				# Available PUT and DELETE on old browsers
				methodOverride req, res, done

		unless /^\/((img|js|css|fonts|components)\/|favicon\.ico)/.test req.originalUrl
			glob __dirname + "/core/global/request/**/*.coffee", (er, files) ->
				pendingFiles = files.length
				if pendingFiles
					files.forEach (file) ->
						value = require file
						if typeof(value) is 'function'
							value req, res, ->
								unless --pendingFiles
									next()
						else
							unless --pendingFiles
								next()
				else
					next()
		else
			next()

	# Launch Kraken
	app.use kraken options

	app.on 'start', ->

		console.log 'Wornet is ready'
		defer.forEach (done) ->
			done app

		glob __dirname + "/core/global/start/**/*.coffee", (er, files) ->
			files.forEach (file) ->
				require file

	app.on 'middleware:after:session', (eventargs) ->
		passport.use auth.localStrategy()
		passport.serializeUser (user, done) ->
			done null, user.id
		passport.deserializeUser (id, done) ->
			User.findOne
				_id: id
			, (err, user) ->
				done null, user
		app.use passport.initialize()
		app.use passport.session()

	# Handle errors and print in the console
	app.listen port, (err) ->
		console.log '[%s] Listening on http://localhost:%d', app.settings.env, port

exports = module.exports = app