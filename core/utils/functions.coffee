'use strict'

module.exports =
	intval: (n) ->
		n = parseInt(n)
		isNaN(n) ? 0 : n
	,
	trim: (str) ->
		str.replace(/^\s+/g, '').replace(/\s+$/g, '')
	,
	empty: (value) ->
		type = typeof(value)
		(
			type is 'undefined' ||
			value is null ||
			value is false ||
			value is 0 ||
			value is "0" ||
			value is "" || (
				type is 'object' && (
					(
						typeof(value.length) isnt 'undefined' &&
						value.length is 0
					) || (
						typeof(value.length) is 'undefined' &&
						typeof(JSON) is 'object' &&
						typeof(JSON.stringify) is 'function' &&
						JSON.stringify(b) is '{}'
					)
				)
			)
		)
	,
	copy: (from, to) ->
		fs.createReadStream(from).pipe(fs.createWriteStream(to))
	s: (val) ->
		val
	,
	lang: ->
		"fr"
	,
	jd: (code) ->
		jadeRender = require('then-jade').render
		jadeRender(code)
	,
	assetUrl: (file, directory, extension) ->
		if config.env.development
			version = fs.statSync('public/' + directory + '/' + file + '.' + extension).mtime.getTime()
		else
			version = config.wornet.version
		'/' + directory + '/' + file + '.' + directory + '?' + version
	,
	style: (file) ->
		assetUrl file, 'css', 'styl'
	,
	script: (file) ->
		assetUrl file, 'js', 'coffee'