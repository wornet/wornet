'use strict'

methodOverride = require('method-override')()
bodyParser = require('body-parser')()

module.exports = (app) ->

	# Before each request
	app.use (req, res, done) ->

		req.res = res
		req.response = res
		res.req = req
		res.request = req
		res.setTimeLimit config.wornet.timeout
		res.on 'finish', ->
			clearTimeout res.excedeedTimeout

		if req.connection.remoteAddress is '127.0.0.1'
			switch req.url
				when '/status'
					return res.end 'OK'

		next = ->
			# Parse body from requests
			bodyParser req, res, ->
				# Available PUT and DELETE on old browsers
				methodOverride req, res, ->
					req.data = extend {}, (req.query || {}), (req.body || {})
					done()
					# To simulate a slow bandwith add a delay like this :
					# delay 3000, done

		req.urlWithoutParams = req.url.replace /\?.*$/g, ''
		if /^\/((img|js|css|fonts|components)\/|favicon\.ico)/.test req.originalUrl
			req.isStatic = true
			ie = req.getHeader('User-Agent').match /MSIE[\/\s]([0-9\.]+)/g
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
					res.setHeader 'cache-control', 'max-age=259200000, public'
					fs.readFile file, ((method, list) ->
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
					)(method, options['main' + ucfirst(lang)]())
					return
			req.url = req.urlWithoutParams
			if req.url.startWith '/img/photo/'
				req.url = profilePhotoUrl req.url
				photoId = PhotoPackage.urlToId req.url
				if photoId and PhotoPackage.restricted req, photoId
					done = ->
						res.notFound()
			else if req.url.startWith '/fonts/glyphicons'
				req.url = '/components/bootstrap' + req.url
			done()
		else
			unless req.xhr
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
