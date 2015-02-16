'use strict'

module.exports = (defer, start) ->

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

	session = require 'express-session'

	if https = config.wornet.protocole is 'https'
		app.set 'trust proxy', 1
	app.use session
		# Express session options
		resave: true,
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

		glob coreDir + 'global/start/**/*.coffee', (er, files) ->
			files.forEach (file) ->
				require file

	listen = (port) ->

		app.listen port, (err) ->
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
