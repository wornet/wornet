'use strict'

module.exports =
	###
	Display a message or variable and stack trace if on a development environment
	@param mixed message or vairbale to print in console log

	@return void
	###
	log: (message) ->
		if config.env.development
			console.log '=========================='
			console.log message
			console.log '--------------------------'
			console.trace()
			console.log '=========================='
	,
	###
	Generate a length-specified random alphanumeric string
	@param int lenght of the returned string

	@return string [A-Za-z0-9]{length} random alphanumeric string
	###
	generateSalt: (length) ->
		SALTCHARS = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789'
		r = ''
		for i in [1..length]
			r += SALTCHARS[Math.floor(Math.random() * SALTCHARS.length)]
		r
	,
	###
	Return integer value or 0 if not able to convert
	"4.7" > 4
	"R" > 0
	@param mixed value to convert

	@return int integer value
	###
	intval: (n) ->
		n = parseInt(n)
		if isNaN(n) then 0 else n
	,
	###
	Return float value or 0 if not able to convert
	"4.7" > 4.7
	"R" > 0
	@param mixed value to convert

	@return int float value
	###
	floatval: (n) ->
		n = parseFloat(n)
		if isNaN(n) then 0 else n
	,
	###
	Return a regex string from RegExpString object get with the specified method (trim if any)
	This can be used in a pattern attribute (HTML5)
	@param string name of the pattern
	@param string|null method of the RegExpString class to use (trim if any)

	@return string matching regular expression
	###
	pattern: (name, method = 'trim') ->
		RegExpString[method] name
	,
	###
	Return a regex from RegExpString object get with the specified method (trim if any)
	This can be used in .match, .replace etc. in controllers
	@param string name of the pattern
	@param string|null method of the RegExpString class to use (trim if any)

	@return RegExp matching regular expression
	###
	regex: (name, method = 'is') ->
		RegExp[method] name
	,
	###
	Remove spaces at begen and end of a given string
	@param string text that can contains spaces

	@return string text without spaces
	###
	trim: (str) ->
		str.replace(/^\s+/g, '').replace(/\s+$/g, '')
	,
	model: (name, schema) ->
		if global[name]? || global[name + 'Model']?
			console.warn name + ' model already token'
			global[name] || global[name + 'Model']
		else
			schema = schema || require(__dirname + '/../../models/' + ucfirst(name) + 'Schema')
			model = mongoose.model name, schema
			global[name] = model
			global[name + 'Model'] = model
	,
	strtolower: (str) ->
		str.toLowerCase()
	,
	strtoupper: (str) ->
		str.toUpperCase()
	,
	ucfirst: (str) ->
		str.charAt(0).toUpperCase() + str.substr(1)
	,
	delay: (ms, cb) ->
		setTimeout cb, ms
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