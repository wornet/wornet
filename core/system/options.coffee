'use strict'

useCdn = false

module.exports = (port) ->
	css: ->
		if useCdn
			# CDN resources
			main: [
				"//maxcdn.bootstrapcdn.com/bootstrap/3.1.1/css/bootstrap.min.css"
				"//maxcdn.bootstrapcdn.com/bootstrap/3.1.1/css/bootstrap-theme.min.css"
				"//ajax.googleapis.com/ajax/libs/jqueryui/1.10.4/themes/smoothness/jquery-ui.css"
				"//cdnjs.cloudflare.com/ajax/libs/fullcalendar/2.0.2/fullcalendar.css"
				style("app")
			]
		else
			# locales resources
			main: [
				"/components/bootstrap/css/bootstrap.min.css"
				"/components/bootstrap/css/bootstrap-theme.min.css"
				"/components/jquery/css/jquery-ui.css"
				"/components/jquery/css/fullcalendar.css"
				style("app")
			]

	js: ->
		if useCdn
			# CDN resources
			main: [
				['if lte IE 9', "//ajax.googleapis.com/ajax/libs/jquery/1.11.1/jquery.min.js"]
				['if gt IE 9', "//ajax.googleapis.com/ajax/libs/jquery/2.1.1/jquery.min.js"]
				['non-ie', "//ajax.googleapis.com/ajax/libs/jquery/2.1.1/jquery.min.js"]
				#"//ajax.googleapis.com/ajax/libs/jqueryui/1.10.4/jquery-ui.min.js"
				"//angular-ui.github.io/ui-calendar/bower_components/jquery-ui/ui/jquery-ui.js"
				"//maxcdn.bootstrapcdn.com/bootstrap/3.1.1/js/bootstrap.min.js"
				"//ajax.googleapis.com/ajax/libs/angularjs/1.3.0-beta.11/angular.min.js"
				"//cdnjs.cloudflare.com/ajax/libs/angular-i18n/1.2.15/angular-locale_fr-fr.js"
				#"//angular-ui.github.io/ui-calendar/bower_components/angular/angular.js"
				"//ajax.googleapis.com/ajax/libs/angularjs/1.3.0-beta.11/angular-animate.min.js"
				#"//ajax.googleapis.com/ajax/libs/angularjs/1.3.0-beta.11/angular-route.js"
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
			main: [
				"/components/jquery/js/jquery.js"
				"/components/jquery/js/jquery-ui.min.js"
				"/components/bootstrap/js/bootstrap.min.js"
				"/components/angular/js/angular.js"
				"/components/angular/js/angular-locale_fr-fr.js"
				"/components/angular/js/angular-animate.js"
				#"//ajax.googleapis.com/ajax/libs/angularjs/1.3.0-beta.11/angular-route.js"
				"/components/bootstrap/js/ui-bootstrap.js"
				"/components/moment/js/moment-with-langs.min.js"
				script("app")
				"/components/jquery/js/fullcalendar.min.js"
				#"/components/jquery/js/fullcalendar-gcal.js"
				"/components/angular/js/calendar-fr.js"
				"/components/angular/js/calendar.js"
			]

	onconfig: (localConfig, next) ->
		# Available shorthand methods to all request objects in controllers
		extend app.request,
			cookie: (name) ->
				if @cookies[name]?
					@cookies[name]
				else
					null
		# Available shorthand methods to all response objects in controllers
		extend app.response,
			json: (data) ->
				data._csrf = data._csrf || @locals._csrf
				@setHeader 'Content-Type', 'application/json'
				@end JSON.stringify data
			notFound: (model = {}) ->
				@status 404
				@render 'errors/404', model
			serverError: (model = {}) ->
				@status 500
				@render 'errors/500', model
			forbidden: (model = {}) ->
				@status 403
				@render 'errors/403', model
			unautorized: (model = {}) ->
				@status 401
				@render 'errors/401', model
		app.set 'views', __dirname + '/../../views'
		extend config, localConfig._store
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
				console.log 'setup/git/' + file + ' >>> .git/' + file

		# Initialize DB
		try
			mongoose.connect 'mongodb://' + config.wornet.db.host + '/' + config.wornet.db.basename
		catch e
			console.warn '\n\n-----------\nUnable to connecte Mongoose. Is MongoDB installed and started?\n'
			console.warn e

		next null, localConfig
