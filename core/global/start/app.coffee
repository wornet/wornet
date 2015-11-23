'use strict'

module.exports = (defer, start) ->

	# Make functions and config usables in views
	extend app.locals, functions
	extend app.locals,
		config: config
		options: options

	if https = config.wornet.protocole is 'https'
		app.set 'trust proxy', 1

	# Get a memcached client to use cache
	memStore = new MemcachedStore
	global.mem = memStore.client

	# Use redis for sessions
	redisStore = new RedisStore
	global.redis = redisStore.client

	redisOnly = require 'redis'
	global.redisClientEmitter = redisOnly.createClient()
	global.redisClientReciever = redisOnly.createClient()

	redisClientReciever.subscribe config.wornet.redis.defaultChannel

	RedisListener()

	session = require 'express-session'

	app.use session
		# Express session options
		resave: false,
		saveUninitialized: false,
		secret: "6qed36sQyAurbQCLNE3X6r6bbtSuDEcU"
		key: "w"
		store: redisStore
		proxy: https
		cookie: secure: https

	do start

	require(coreDir + 'global/request/handle-static') app

	app.on 'start', ->

		console['log'] 'Wornet is ready  ' + (new Date).log()

		defer.forEach (done) ->
			done app

		defer.done = true

		glob coreDir + 'global/start/**/*.coffee', (er, files) ->
			files.forEach (file) ->
				require file

	listen = (port) ->

		global.server = app.listen port, (err) ->
			if err
				throw err
			else
				console['log'] '[%s] Listening on http://localhost:%d', app.settings.env, port


	# Handle errors and print in the console
	if config.port is 443

		app.all '*', (req, res, next) ->
			if req.secure
				next()
			else
				res.redirect 'https://' + req.hostname + req.url

		listen 80
		listen 443
	else
		listen config.port
