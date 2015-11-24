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
		unless port is 8002
			global.server = app.listen port, (err) ->
				if err
					throw err
				else
					console['log'] '[%s] Listening on http://localhost:%d', app.settings.env, port
		else
			caFiles = ['crossRootCA.cer', 'IntermediateCA.cer', 'SymantecClass3SecureServerCA-G4.txt', 'VeriSignClass3PublicPrimaryCertificationAuthority-G5.txt']
			ca = []
			options =
				key: fs.readFileSync '/etc/ssl/private/key.pem'
				ca: ca
				cert: fs.readFileSync '/etc/ssl/private/certificate.cer'

			global.server = httpsServer.createServer(options, app).listen port, (err) ->
				if err
					throw err
				else
					console['log'] '[%s] Listening on https://localhost:%d', app.settings.env, port

	# Handle errors and print in the console
	if config.port is 443
		global.httpsServer = require 'https'
		app.all '*', (req, res, next) ->
			if req.secure
				next()
			else
				res.redirect 'https://' + req.hostname + req.url

		#for http requests
		listen 8001
		#for https requests
		listen 8002
	else
		listen config.port
