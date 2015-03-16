'use strict'

class PagesManager
	_router: null
	_templateFolder: null
	constructor: (router, templateFolder) ->
		@_router = router
		@_templateFolder = templateFolder || ''
	multiUpload: (url, callback) ->
		@_router.post url, (req, res) ->
			req.multiUpload (files) ->
				req.files = files
				callback req, res
	page: (url, callback, method) ->
		method ||= 'get'
		template = (@_templateFolder + url).replace /^\//g, ''
		@_router[method] url, (req, res) ->
			rendered = false
			haveThreeParameters = false
			if typeof(callback) is 'function'
				haveThreeParameters = /^[^,{]+,[^,{]+,[^,{]+\{/g.test callback.toString()
				model = callback req, res, (model) ->
					unless rendered
						res.render template, model
			else
				model = {}
			unless haveThreeParameters or model is null
				rendered = true
				res.render template, model
		@

module.exports = PagesManager
