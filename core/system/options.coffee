'use strict'

useCdn = false

module.exports = (port) ->
	css: ->
		if useCdn
			# CDN resources
			main: [
				"//maxcdn.bootstrapcdn.com/bootstrap/3.1.1/css/bootstrap.min.css",
				"//maxcdn.bootstrapcdn.com/bootstrap/3.1.1/css/bootstrap-theme.min.css",
				style("app")
			]
		else
			# locales resources
			main: [
				"/components/bootstrap/css/bootstrap.min.css",
				"/components/bootstrap/css/bootstrap-theme.min.css",
				style("app")
			]

	js: ->
		if useCdn
			# CDN resources
			main: [
				['if IE lte 9', "//ajax.googleapis.com/ajax/libs/jquery/1.11.1/jquery.min.js"],
				['if IE gt 9', "//ajax.googleapis.com/ajax/libs/jquery/2.1.1/jquery.min.js"],
				['non-ie', "//ajax.googleapis.com/ajax/libs/jquery/2.1.1/jquery.min.js"],
				"//maxcdn.bootstrapcdn.com/bootstrap/3.1.1/js/bootstrap.min.js",
				"//ajax.googleapis.com/ajax/libs/angularjs/1.3.0-beta.11/angular.min.js",
				"//ajax.googleapis.com/ajax/libs/angularjs/1.3.0-beta.11/angular-animate.min.js",
				script("app")
			]
		else
			# locales resources
			main: [
				"/components/jquery/js/jquery.js",
				"/components/bootstrap/js/bootstrap.min.js",
				"/components/angular/js/angular.js",
				"/components/angular/js/angular-animate.js",
				script("app")
			]

	onconfig: (localConfig, next) ->
		extend config, localConfig._store
		if port is 8000 && config.env.development
			(['config', 'hooks/post-receive', 'hooks/post-receive.bat', 'hooks/pre-commit', 'hooks/pre-commit.bat']).forEach (file) ->
				copy 'setup/git/' + file, '.git/' + file
				console.log 'setup/git/' + file + ' >>> .git/' + file
		next null, localConfig