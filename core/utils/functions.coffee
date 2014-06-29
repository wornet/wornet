'use strict'

module.exports =
	intval: (n) ->
		n = parseInt(n)
		if isNaN(n) then 0 else n
	,
	floatval: (n) ->
		n = parseFloat(n)
		if isNaN(n) then 0 else n
	,
	pattern: (name, method) ->
		method = method || 'trim'
		RegExpString[method] name
	,
	regex: (name, method) ->
		method = method || 'is'
		RegExp[method] name
	,
	trim: (str) ->
		str.replace(/^\s+/g, '').replace(/\s+$/g, '')
	,
	strtolower: (str) ->
		str.toLowerCase()
	,
	strtoupper: (str) ->
		str.toUpperCase()
	,
	delay: (ms, cb) ->
		setTimeout cb, m
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
						JSON.stringify(value) is '{}'
					)
				)
			)
		)
	,
	copy: (from, to) ->
		fs.createReadStream(from).pipe(fs.createWriteStream(to))
	,
	s: (text, replacements, count) ->
		local lang(), text, replacements, count
	,
	lang: ->
		"fr"
	,
	jd: (code) ->
		jadeRender = require('jade').render
		jadeRender(code)
	,
	data: (name, value) ->
		try
			name = name.replace(/(\\|")/g, '\\$1')
			value = JSON.stringify(value).replace(/(\\|")/g, '\\$1')
			jd 'div(data-data, data-name="' + name + '", data-value="' + value + '")'
		catch e
			console.error e
			console.trace()
			"Error (see conole)"
	,
	shareData: (name, value) ->
		if typeof(value) is 'undefined'
			extend app.locals, name
		else
			app.locals[name] = value
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