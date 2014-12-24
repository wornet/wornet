'use strict'

class PagesManager
	_router: null
	_templateFolder: null
	constructor: (router, templateFolder) ->
		@_router = router
		@_templateFolder = templateFolder || ''
	page: (url, callback, method) ->
		method ||= 'get'
		template = (@_templateFolder + url).replace(/^\//g, '')
		@_router[method] url, (req, res) ->
			rendered = false
			if typeof(callback) is 'function'
				model = callback req, res, (model) ->
					unless rendered
						res.render template, model
			else
				model = {}
			unless model is null
				rendered = true
				res.render template, model
		@

module.exports = PagesManager
