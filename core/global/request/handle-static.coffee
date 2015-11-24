'use strict'

methodOverride = do require 'method-override'
bodyParser = do require 'body-parser'
proxy = require('http-proxy').createProxyServer {}
zlib = require 'zlib'

module.exports = (app) ->

	templates = []
	markdowns = []
	dateTimeAtStart = null
	fs.realpath __dirname + '/../../../views/templates', (err, dir) ->
		unless err
			glob dir + '/**', (err, _templates) ->
				unless err
					for path in _templates
						do (path) ->
							fs.stat path, (err, stat) ->
								if ! err and stat.isFile()
									templates.push path.substring dir.length, path.length - 5
	fs.realpath __dirname + '/../../../views/includes', (err, dir) ->
		unless err
			glob dir + '/**', (err, _markdowns) ->
				unless err
					for path in _markdowns
						do (path) ->
							if path.endWith '.md'
								fs.stat path, (err, stat) ->
									if ! err and stat.isFile()
										markdowns.push path.substring dir.length, path.length - 3

	if !dateTimeAtStart
		dateTimeAtStart = do ->
			today = new Date()
			today.getFullYear() + '-' + today.getMonth() + '-' + today.getDate() + '_' + today.getHours() + '-' + today.getMinutes() + '-' + today.getSeconds()
	fs.exists __dirname + '/../../../routeLog/', (exists) ->
		unless exists
			fs.mkdir __dirname + '/../../../routeLog/'

	# Before each request
	app.use (req, res, done) ->

		if config.wornet.logRoutes
			fileName =  dateTimeAtStart + '-routes.log'
			fs.appendFile  __dirname + '/../../../routeLog/' + fileName, '\n' + req.url, (err) ->
				return

		req.urlWithoutParams = req.url.replace /\?.*$/g, ''
		req.response = res
		res.request = req
		res.setTimeLimit if req.is 'multipart/form-data'
			config.wornet.upload.timeout
		else
			config.wornet.timeout
		res.on 'finish', ->
			clearTimeout res.excedeedTimeout

		basicAuth = config.basicAuth || null
		if req.connection.remoteAddress is '127.0.0.1'
			basicAuth = null
			switch req.url
				when '/status'
					return res.end 'OK'
				when '/alive'
					if User
						User.find().limit(1).exec (err, user) ->
							if user and ! err
								res.end 'alive'
					return

		next = ->
			bodyParser req, res, ->
				# Available PUT and DELETE on old browsers
				methodOverride req, res, ->
					req.data = extend {}, (req.query || {}), (req.body || {})
					done()
					# To simulate a slow bandwith add a delay like this :
					# delay 3000, done

		userAgent = (req.getHeader 'user-agent') || ''
		isMobile = -1 isnt userAgent.indexOf 'Mobile'
		iosApp = isMobile and -1 is userAgent.indexOf 'Safari/'
		if req.urlWithoutParams is '/stat'
			piwik = options.trackers().piwik
			if piwik and piwik.target
				for key in [
					[req, 'url']
					[req, 'originalUrl']
					[req, 'urlWithoutParams']
					[req._parsedUrl, 'pathname']
					[req._parsedUrl, 'path']
					[req._parsedUrl, 'href']
				]
					key[0][key[1]] = key[0][key[1]].replace /^\/stat/, '/piwik.php'
				tries = 0
				do _try = ->
					proxy.web req, res, target: piwik.target, (err) ->
						if err
							if ++tries < 3
								do _try
							else
								res.end()
			else
				res.notFound()
		else if /^\/((img|js|css|fonts|components|template)\/|favicon\.ico)/.test req.originalUrl
			res.setHeader 'cache-control', 'max-age=' + 90.days + ', public'
			req.isStatic = true
			if req.urlWithoutParams.startWith '/template/'
				path = req.urlWithoutParams.substr 9
				if path in templates
					fs.readFile __dirname + '/../../../views/templates' + path + '.jade', (err, contents) ->
						if err
							res.notFound()
						else
							res.end jd contents
				else if path in markdowns
					fs.readFile __dirname + '/../../../views/includes' + path + '.md', (err, contents) ->
						if err
							res.notFound()
						else
							res.end md contents
				else
					res.notFound()
			else
				ie = userAgent.match /MSIE[\/\s]([0-9\.]+)/g
				ie = if ie
					intval ie[0].substr 5
				else
					0
				req.ie = ie
				req.iosApp = iosApp
				methods =
					js: uglifyJs
					css: (str) ->
						str
							.replace /[\r\n\t]/g, ''
							.replace /\s+([\}\{;:])\s*/g, '$1'
							.replace /\s*([\}\{;:])\s+/g, '$1'
							.replace /;\}/g, '}'
				###
				In production mode, all scripts are minified with UglifyJS and joined in /js/all.js
				And all styles are minified with deleting \r, \n and \t and joined in /css/all.css
				###
				for lang, method of methods
					if req.urlWithoutParams is '/' + lang + '/all.' + lang
						res.setTimeLimit 200
						acceptEncoding = (req.getHeader 'accept-encoding') || ''
						file = __dirname + '/../../../.build/' + lang + '/all' + (
							if iosApp
								'-ios-app'
							else if ie
								'-ie-' + ie
							else
								''
						) + '.' + lang
						gzip = /\bgzip\b/.test acceptEncoding
						if gzip
							file += '.gz'
							compressMethod = zlib.gzip.bind zlib
						else
							compressMethod = (content, done) ->
								done null, content
						res.setHeader 'content-type', 'text/' + (if lang is 'js' then 'javascript' else 'css') + '; charset=utf-8'
						list = options['main' + ucfirst(lang)]()
						fs.readFile file, do (method, list) ->
							(err, content) ->
								if err
									concatCallback '', list, method, (content) ->
										# content = uglifyJs content
										compressMethod content, (err, compressedContent) ->
											if compressedContent and ! err
												if gzip
													res.setHeader 'content-encoding', 'gzip'
												res.end compressedContent
												fs.writeFile file, compressedContent
									,
										ie: ie
										iosApp: iosApp
								else
									if gzip
										res.setHeader 'content-encoding', 'gzip'
									res.end content
						return
				req.url = req.urlWithoutParams
				if req.url.startWith '/img/photo/'
					if '@' is (req.originalUrl.substr -7, 1) and 'x.' is (req.originalUrl.substr -5, 2)
						isMobile = false
						req.url = req.originalUrl
					req.url = profilePhotoUrl req.url
					photoId = PhotoPackage.urlToId req.url
					if photoId and PhotoPackage.restricted req, photoId
						res.notFound()
						return
					if isMobile
						path = mobilePath req.url
						fs.exists __dirname + '/../../../public' + path, (exists) ->
							if exists
								req.url = path
							done()
						return
				else if req.url.startWith '/fonts/glyphicons'
					req.url = '/components/bootstrap' + req.url
					# Allow cross-origin from all wornet.fr subdomains
					res.header 'access-control-allow-origin', '*'
					res.header 'access-control-allow-methods', 'GET'
				done()
		else
			# Secure with basic authentification in requiered in config
			if basicAuth
				saveUser = null
				if req.user
					saveUser = req.user
				do (req, res, next) ->
					(require 'basic-auth-connect')(basicAuth.username, basicAuth.password) req, res, ->
						if typeof(req.user) is 'string'
							req.username = req.user
							if saveUser
								req.user = saveUser
							else
								delete req.user
						next()
				return
			unless req.xhr
				unless req.connection.remoteAddress is '127.0.0.1'
					secure = req.secure or 'https' is req.getHeader 'x-forwarded-proto'
					if (config.wornet.protocole is 'https') isnt secure or config.wornet.redirectToDefaultHost is req.getHeader 'host'
						res.redirect config.wornet.protocole +  '://' + config.wornet.defaultHost + req.url
						return
				# Do not re-open connection for resources
				res.setHeader 'keep-alive', 'timeout=15, max=100'
			res.locals.isXHR = !!req.xhr
			res.locals.iosApp = iosApp
			res.isXHR = res.locals.isXHR
			req.isJSON = req.getHeader('accept').match /(application\/json|text\/javascript)/g
			res.isJSON = req.isJSON
			StatisticsPackage.track req.method, req.url, res.isXHR
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
