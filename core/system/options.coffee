'use strict'

useCdn = false
piwik = true
googleAnalytics = true

module.exports = (port) ->

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
				else
					log url
					@session.goingTo = url
				url
			# Get a cookie value from name or null if it does not exists
			cookie: (name) ->
				if @cookies[name]?
					@cookies[name]
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
				, (err, result, cached) ->
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
				if req.session.user.notifications
					notifications = []
					for notification in req.session.user.notifications
						unless notification[0] is id
							notifications.push notification
					req.session.user.notifications = notifications
					req.user.notifications = notifications
					done null, notifications
				else
					done new Error "No notifications"
			# get users from friend, me
			getKnownUsersByIds: (ids, done) ->
				@getUsersByIds ids, done, false
			# get users from friend, me, or from database
			getUsersByIds: (ids, done, searchInDataBase = true) ->
				currentUser = @user
				ids = ids.map strval
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
							true
						if idsToFind.length > 0
							if searchInDataBase
								User.find id: $in: idsToFind, (err, otherUsers) ->
									if err
										done err, null, true
									else
										err = (if otherUsers.length is idsToFind.length
											null
										else
											new Error s("Impossible de trouver tous les utilisateurs")
										)
										otherUsers.each ->
											usersMap[@id] = @
											true
										done err, usersMap, true
							else
								err = new Error s("Impossible de trouver tous les utilisateurs")
								done err, null, false
						else
							done null, usersMap, false


		# Save original method(s) that we will override
		redirect = app.response.redirect

		# Available shorthand methods to all response objects in controllers
		responseErrors =
			notFound: 404
			serverError: 500
			forbidden: 403
			unautorized: 401
		for key, val of responseErrors
			app.response[key] = ((key, val) ->
				(model = {}) ->
					if typeof(model) is 'string' or model instanceof Error
						model = err: model
					err = ((@locals || {}).err || model.err) || new Error "Unknown " + val + " " + key.replace(/Error$/g, '').replace(/([A-Z])/g, ' $&').toLowerCase() + " error"
					warn err
					if config.env.development
						model.err = err
					@status val
					if @isJSON
						model.statusCode = val
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
			json: (data = {}) ->
				if typeof @ is 'undefined'
					log "No context"
				if data.statusCode? and data.statusCode is 500
					if data.err instanceof Error and config.env.development
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
						res.serverError new Error s("Navré, nous n'avons pas pu traiter votre demande, veuillez réessayer ultérieurement.")
			catch: (callback) ->
				res = @
				->
					try
						callback()
					catch e
						res.serverError e



		# Templates directory
		app.set 'views', __dirname + '/../../views'

		# Add config.json configuration
		extend config, localConfig._store

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

		next null, localConfig
