'use strict'

useCdn = false
piwik = true
googleAnalytics = true

flash = require('connect-flash')
cookieParser = require(config.middleware.cookieParser.module.name)

module.exports = (app, port) ->

	cookiesInit = ->
		cookieParser.apply app, config.middleware.cookieParser.module.arguments

	# Trace the error in log when user(s) are not found
	someUsersNotFound = ->
		err = new PublicError s("Impossible de trouver tous les utilisateurs")
		warn err
		err

	app.on 'middleware:after:session', (eventargs) ->
		# Flash session (store data in sessions to the next page only)
		app.use flash()
		# Allow to set and get cookies in routes methods
		app.use cookiesInit()

		# Check if user is authentificated and is allowed to access the requested URL
		app.use auth.isAuthenticated

		# Store sessions in Memcached
		###
		app.use(session(
			secret: config.session.module.arguments[0].secret
			key: config.session.module.arguments[0].key
			store: new MemcachedStore
				hosts: ['127.0.0.1:11211']
		))
		###

	trackers: ->
		trackers = {}
		if piwik
			trackers.piwik =
				id: 8
				host: 'piwik.selfbuild.fr'
		if googleAnalytics
			trackers.googleAnalytics =
				id: 'UA-54493690-1'
		trackers

	mainCss: ->
		if useCdn
			# CDN resources
			[
				"//maxcdn.bootstrapcdn.com/bootstrap/3.1.1/css/bootstrap.min.css"
				"//maxcdn.bootstrapcdn.com/bootstrap/3.1.1/css/bootstrap-theme.min.css"
				"//ajax.googleapis.com/ajax/libs/jqueryui/1.10.4/themes/smoothness/jquery-ui.css"
				"//cdnjs.cloudflare.com/ajax/libs/fullcalendar/2.0.2/fullcalendar.css"
				style("app")
			]
		else
			# locales resources
			[
				"/components/bootstrap/css/bootstrap.min.css"
				"/components/bootstrap/css/bootstrap-theme.min.css"
				"/components/jquery/css/jquery-ui.css"
				"/components/jquery/css/fullcalendar.css"
				style("app")
			]

	css: ->
		if config.env.development
			main: @mainCss()
		else
			main: [style("all")]

	mainJs: ->
		if useCdn
			# CDN resources
			[
				['if lt IE 9', "//ajax.googleapis.com/ajax/libs/jquery/1.11.1/jquery.min.js"]
				['if gte IE 9', "//ajax.googleapis.com/ajax/libs/jquery/2.1.1/jquery.min.js"]
				['non-ie', "//ajax.googleapis.com/ajax/libs/jquery/2.1.1/jquery.min.js"]
				#"//ajax.googleapis.com/ajax/libs/jqueryui/1.10.4/jquery-ui.min.js"
				"//angular-ui.github.io/ui-calendar/bower_components/jquery-ui/ui/jquery-ui.js"
				"//maxcdn.bootstrapcdn.com/bootstrap/3.1.1/js/bootstrap.min.js"
				"//cdnjs.cloudflare.com/ajax/libs/fastclick/1.0.3/fastclick.min.js"
				"//cdnjs.cloudflare.com/ajax/libs/bootbox.js/4.3.0/bootbox.min.js"
				#"//ajax.googleapis.com/ajax/libs/angularjs/1.3.2/angular.min.js"
				"//ajax.googleapis.com/ajax/libs/angularjs/1.3.2/angular-animate.min.js"
				"//ajax.googleapis.com/ajax/libs/angularjs/1.3.2/angular-sanitize.min.js"
				"//cdnjs.cloudflare.com/ajax/libs/angular-i18n/1.2.15/angular-locale_fr-fr.js"
				#"//ajax.googleapis.com/ajax/libs/angularjs/1.3.0-beta.11/angular-route.js"
				#"//angular-ui.github.io/ui-calendar/bower_components/angular/angular.js"
				"//angular-ui.github.io/bootstrap/ui-bootstrap-tpls-0.9.0.js"
				"//rawgit.com/angular-ui/ui-calendar/master/src/calendar.js"
				"//rawgit.com/angular-ui/ui-calendar/master/src/calendar.js"
				"//cdnjs.cloudflare.com/ajax/libs/moment.js/2.7.0/moment-with-langs.min.js"
				#"//cdnjs.cloudflare.com/ajax/libs/moment.js/2.7.0/moment.min.js"
				"//cdnjs.cloudflare.com/ajax/libs/fullcalendar/2.0.2/fullcalendar.min.js"
				#"//cdnjs.cloudflare.com/ajax/libs/fullcalendar/2.0.2/lang/fr.js"
				#"//arshaw.com/js/fullcalendar-1.5.3/fullcalendar/gcal.js"
				"/components/angular/js/calendar-fr.js"
				"//rawgit.com/angular-ui/ui-calendar/master/src/calendar.js"
				script("app")
			]
		else
			# locales resources
			[
				['if lt IE 9', "/components/css3-mediaqueries/js/css3-mediaqueries.js"]
				['if lt IE 9', "/components/jquery/js/jquery-1.js"]
				['if gte IE 9', "/components/jquery/js/jquery-2.js"]
				['non-ie', "/components/jquery/js/jquery-2.js"]
				"/components/jquery/js/jquery-ui.min.js"
				"/components/bootstrap/js/bootstrap.min.js"
				#"/components/angular/js/angular.js"
				"/components/angular/js/angular-animate.js"
				"/components/angular/js/angular-locale_fr-fr.js"
				"/components/angular/js/angular-sanitize.js"
				#"//ajax.googleapis.com/ajax/libs/angularjs/1.3.0-beta.11/angular-route.js"
				"/components/bootstrap/js/ui-bootstrap-tpls.min.js"
				"/components/bootstrap/js/bootbox.min.js"
				"/components/fastclick/js/fastclick.min.js"
				"/components/moment/js/moment-with-langs.min.js"
				script("app")
				"/components/jquery/js/fullcalendar.min.js"
				#"/components/jquery/js/fullcalendar-gcal.js"
				"/components/angular/js/calendar-fr.min.js"
				"/components/angular/js/calendar.min.js"
			]

	js: ->
		if config.env.development
			main: @mainJs()
		else
			main: [script("all")]

	onconfig: (localConfig, next) ->
		# Available shorthand methods to all request objects in controllers
		extend app.request,
			# get objets of the different alert types for a given key
			getAlerts: (key) ->
				danger: @flash key + 'Errors'
				success: @flash key + 'Success'
				info: @flash key + 'Infos'
				warning: @flash key + 'Warnings'
			# get id from hashed or the id of the user logged in if it's null
			getRequestedUserId: (id) ->
				if id is null
					@user.id
				else
					cesarRight id
			# get request header or empty string if it's not contained
			getHeader: (name) ->
				@headers[name.toLowerCase()] || ''
			# Ask for redirect at next request
			goingTo: (url = null) ->
				if url is null
					if @session.goingTo?
						url = @session.goingTo
						delete @session.goingTo
				else if url isnt '/user/notify'
					@session.goingTo = url
				url
			# Get a cookie value from name or null if it does not exists
			cookie: (name) ->
				if @cookies[name]?
					@cookies[name]
				else if @signedCookies[name]?
					@signedCookies[name]
				else
					null
			# Get from cache if present in user session, else calculate
			cache: (key, calculate, done) ->
				if typeof(key) is 'function'
					done = calculate
					calculate = key
					key = codeId()
				unless @session.cache?
					@session.cache = {}
				cache = @session.cache
				if typeof cache[key] is 'undefined'
					calculate (err, value) ->
						unless err
							cache[key] = value
						done err, value, false
				else
					done null, cache[key], true
			# Empty the user session cache
			cacheFlush: (key = null) ->
				if key is null
					@session.cache = {}
				else
					delete @session.cache[key]
			# get friends of the user logged in
			getFriends: (done) ->
				user = @user
				@cache 'friends', (done) ->
					user.getFriends (err, friends, friendAsks) ->
						done err, [friends, friendAsks]
				, (err, result) ->
					if err
						done err, {}, {}
					else
						friends = result[0]
						friendAsks = result[1]
						done err, friends, friendAsks
			# add a friend to the current user
			addFriend: (user) ->
				@user.friends.push user
				@user.numberOfFriends = @user.friends.length
				@session.user.friends = @user.friends
				@session.user.numberOfFriends = @session.user.friends.length
			# delete a notification
			deleteNotification: (id) ->
				if @session.user.notifications
					notifications = []
					for notification in @session.user.notifications
						unless notification[0] is id
							notifications.push notification
					@session.user.notifications = notifications
					@user.notifications = notifications
					done null, notifications
				else
					done new PublicError s("Aucune notification")
			# get users from friend, me
			getKnownUsersByIds: (ids, done) ->
				@getUsersByIds ids, done, false
			# get users from friends, me, or from database
			getUsersByIds: (ids, done, searchInDataBase = true) ->
				currentUser = @user
				ids = ids.map strval
				if ids.contains 'undefined'
					throw new Error 'ids must not contain undefined'
				idsToFind = []
				usersMap = {}
				req = @
				@getFriends (err, friends, friendAsks) ->
					if err
						done err, null, false
					else
						ids.each ->
							user = (if @ is currentUser.id
								currentUser
							else
								friends.findOne id: @
							)
							if user
								usersMap[@] = objectToUser user
							else
								idsToFind.push @
						if idsToFind.length > 0
							if searchInDataBase
								User.find _id: $in: idsToFind, (err, otherUsers) ->
									if err
										done err, null, true
									else
										err = (if otherUsers.length is idsToFind.length
											null
										else
											someUsersNotFound()
										)
										otherUsers.each ->
											usersMap[@id] = @
										done err, usersMap, true
							else
								done someUsersNotFound(), null, false
						else
							done null, usersMap, false
			# get user from friends, me, or from database
			getUserById: (id, done, searchInDataBase = true) ->
				@getUsersByIds [id], (err, usersMap) ->
					if err or ! usersMap or ! usersMap[id]
						done someUsersNotFound()
					else
						done null, usersMap[id]


		# Save original method(s) that we will override
		redirect = app.response.redirect
		setHeader = app.response.setHeader
		render = app.response.render
		end = app.response.end
		cookie = app.response.cookie

		# Available shorthand methods to all response objects in controllers
		responseErrors =
			notFound: 404
			serverError: 500
			forbidden: 403
			unautorized: 401
		for key, val of responseErrors
			app.response[key] = ((key, val) ->
				(model = {}) ->
					if typeof(model) is 'string' or model instanceof Error or model instanceof PublicError
						model = err: model
					err = ((@locals || {}).err || model.err) || new Error "Unknown " + val + " " + key.replace(/Error$/g, '').replace(/([A-Z])/g, ' $&').toLowerCase() + " error"
					warn err, false
					GitlabPackage.error 'Error ' + val + '\n' + @req.getHeader('referrer') + '\n' + err
					model.err = err
					model.statusCode = val
					@status val
					if @isJSON
						@json model
					else
						@render 'errors/' + val, model
			) key, val

		extend app.response,
			###
			Complete a local URL if needed
			@param string URL

			@return string complete URL
			###
			localUrl: (path) ->
				if config.wornet.parseProxyUrl and path.charAt(0) is '/'
					for proxy in config.wornet.proxies
						if (proxy.indexOf('https://') is 0 and !@secure) or (proxy.indexOf('http://') is 0 and @secure)
							continue
						proxy = proxy.replace(/https?:\/\//g, '').split /\//g
						if proxy.length > 1 and proxy[0] is @hostname
							return '/' + proxy.slice(1).join('/') + path
				path
			redirect: ->
				params = Array.prototype.slice.call arguments
				if typeof params[0] is 'string'
					params[0] = @localUrl params[0]
				redirect.apply @, params
			safeHeader: (done) ->
				try
					done()
				catch e
					if equals e, "Error: Can't set headers after they are sent."
						if @endAt
							warn @endAt
						else if @setHeaderAt
							warn @setHeaderAt
						throw e
					else
						throw e
			setHeader: ->
				@setHeaderAt = new Error "End here:"
				res = @
				params = arguments
				@safeHeader ->
					setHeader.apply res, params
			render: ->
				res = @
				params = arguments
				if params[1] and params[1].err and ! config.env.development
					if params[1].err instanceof PublicError
						params[1].err = strval params[1].err
					else
						delete params[1].err
				@safeHeader ->
					render.apply res, params
			end: ->
				@endAt = new Error "End here:"
				res = @
				params = arguments
				@safeHeader ->
					end.apply res, params
			json: (data = {}) ->
				if typeof @ is 'undefined'
					log "No context"
				if data.statusCode? and data.statusCode is 500
					if data.err instanceof Error
						if equals data.err, "Error: CSRF token mismatch"
							data.csrfBroken = true
						if config.env.development
							data.stack = data.err.stack
					data.err = strval(data.err || s("Erreur inconnue"))
				data._csrf = data._csrf || @locals._csrf
				@setHeader 'Content-Type', 'application/json'
				@end JSON.stringify data
			setTimeLimit: (time = 0) ->
				if typeof(@excedeedTimeout) isnt 'undefined'
					clearTimeout @excedeedTimeout
				if time > 0
					res = @
					@excedeedTimeout = delay time.seconds, ->
						res.serverError new PublicError s("Navré, nous n'avons pas pu traiter votre demande, veuillez réessayer ultérieurement.")
			catch: (callback) ->
				res = @
				->
					try
						callback()
					catch e
						res.serverError e
			cookie: (name, value, options = {}) ->
				if config.wornet.protocole is 'https' and typeof options.secure is 'undefined'
					options.secure = true
				if typeof options.domain is 'object'
					host = options.domain.hostname || options.domain.host
					if host
						newHost = host.replace /^[^\.]+(\.[^\.]+\.[^\.]+)$/g, '$1'
						if host is newHost
							delete options.domain
						else
							options.domain = newHost
				params = arguments
				params[2] = options
				cookie.apply @, params


		# Templates directory
		app.set 'views', __dirname + '/../../views'

		# Add config.json configuration
		deepextend config, localConfig._store
		if customConfig
			deepextend config, customConfig

		# Initialize packages
		MailPackage.init()

		# Start tasks
		glob __dirname + '/../tasks/*.coffee', (er, files) ->
			files.map require

		# Prettify or minify the HTML output as configured
		app.locals.pretty = true if config.wornet.prettyHtml

		# Assets images in stylus code
		['png', 'jpg', 'gif'].forEach (ext) ->
			stylus.functions[ext] = (url) ->
				functions[ext](url, config.wornet.asset.image.base64Limit)
			stylus.functions['big' + ucfirst(ext)] = (url) ->
				functions[ext](bigImg(url), config.wornet.asset.image.base64Limit)
		stylus.functions.bigImg = bigImg
		stylus.functions.quote = quoteString

		# Available s() in stylus files
		stylus.functions.s = functions.s

		# Copy hooks
		if port is 8000 && config.env.development
			[
				#'config'
				'hooks/pre-commit'
				'hooks/pre-commit.bat'
				'hooks/pre-push'
				'hooks/pre-push.bat'
				'hooks/post-receive'
				'hooks/post-receive.bat'
				'hooks/post-merge'
				'hooks/post-merge.bat'
			].forEach (file) ->
				copy 'setup/git/' + file, '.git/' + file
				console['log'] 'setup/git/' + file + ' >>> .git/' + file
			# To document with JsDoc
			# require(__dirname + "/command")("jsdoc -c ./doc/conf.json -r -d ./doc/ .")

		# Initialize DB
		try
			mongoose.connect 'mongodb://' + config.wornet.db.host + '/' + config.wornet.db.basename
		catch e
			console['warn'] '\n\n-----------\nUnable to connect Mongoose. Is MongoDB installed and started?\n'
			console['warn'] e

		deepextend localConfig._store, middleware: logger: module: arguments: [
			"combined",
			skip: (req, res) ->
				global.muteLog or (! config.env.development and res.statusCode < 400)
		]

		next null, localConfig
