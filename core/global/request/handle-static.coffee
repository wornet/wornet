'use strict'

methodOverride = do require 'method-override'
bodyParser = do require 'body-parser'

module.exports = (app) ->

	# Before each request
	app.use (req, res, done) ->

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
			# Parse body from requests
			if req.is 'multipart/form-data'
				formidable = require 'formidable'
				form = new formidable.IncomingForm()
				files = {}
				form.parse req
				form.on 'file', (name, file) ->
					unless files[name]
						files[name] = []
					files[name].push file
				form.on 'end', ->
					req.triggerMultiUpload files
			bodyParser req, res, ->
				# Available PUT and DELETE on old browsers
				methodOverride req, res, ->
					req.data = extend {}, (req.query || {}), (req.body || {})
					done()
					# To simulate a slow bandwith add a delay like this :
					# delay 3000, done

		if /^\/((img|js|css|fonts|components)\/|favicon\.ico)/.test req.originalUrl
			res.setHeader 'cache-control', 'max-age=' + 90.days + ', public'
			req.isStatic = true
			ie = req.getHeader('user-agent').match /MSIE[\/\s]([0-9\.]+)/g
			if ie
				ie = intval ie[0].substr 5
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
				if req.urlWithoutParams is '/' + lang + '/all.' + lang
					res.setTimeLimit 200
					file = __dirname + '/../../../.build/' + lang + '/all-ie-' + req.ie + '.' + lang
					res.setHeader 'content-type', 'text/' + (if lang is 'js' then 'javascript' else 'css') + '; charset=utf-8'
					list = options['main' + ucfirst(lang)]()
					fs.readFile file, do (method, list) ->
						(err, content) ->
							if err
								concatCallback '', list, method, (content) ->
									# content = uglifyJs content
									res.end content
									fs.writeFile file, content
								,
									ie: req.ie
							else
								res.end content
					return
			req.url = req.urlWithoutParams
			if req.url.startWith '/img/photo/'
				req.url = profilePhotoUrl req.url
				photoId = PhotoPackage.urlToId req.url
				if photoId and PhotoPackage.restricted req, photoId
					res.notFound()
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
			unless req.xhr or req.connection.remoteAddress is '127.0.0.1'
				secure = req.secure or 'https' is req.getHeader 'x-forwarded-proto'
				if config.wornet.protocole is 'https' isnt secure or config.wornet.redirectToDefaultHost is req.getHeader 'host'
					res.redirect config.wornet.protocole +  '://' + config.wornet.defaultHost + req.url
					return
				# Do not re-open connection for resources
				res.setHeader 'keep-alive', 'timeout=15, max=100'
			res.locals.isXHR = !!req.xhr
			res.isXHR = res.locals.isXHR
			req.isJSON = req.getHeader('accept').match /(application\/json|text\/javascript)/g
			res.isJSON = req.isJSON
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
