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
	###
	Load model if it is not already. In any case, return it
	@param string model name
	@param Schema schema for generate the model
				  (if any given, the file is used name = "myModel", a MyModelSchema.coffee file
				  must exist in models/ directory)

	@return Model asked model
	###
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
	###
	Return a string in lower case
	@param string text in any case

	@return string text in lower case
	###
	strtolower: (str) ->
		str.toLowerCase()
	,
	###
	Return a string in upper case
	@param string text in any case

	@return string text in upper case
	###
	strtoupper: (str) ->
		str.toUpperCase()
	,
	###
	Return a string with first character in upper case
	@param string text in any case

	@return string text with first character in upper case
	###
	ucfirst: (str) ->
		str.charAt(0).toUpperCase() + str.substr(1)
	,
	###
	Shorthand to exec a callback after a delay specified in milliseconds
	@param integer delay
	@param function callback

	@return integer timeout identifier (could be passed to a clearTimeout function)
	###
	delay: (ms, cb) ->
		setTimeout cb, ms
	,
	###
	Test if a value is empty in a very tolerant way
	@param mixed value to check

	@return boolean (true if value is undefined, null, false, 0, "0", "", {}, [], or a 0-length object)
	###
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
	###
	Copy a file in a new path
	@param string source file
	@param string destination file

	@return boolean true if succeed, false else
	###
	copy: (from, to) ->
		fs.createReadStream(from).pipe(fs.createWriteStream(to))
	,
	###
	Applying replacemens and pluralization in a given text
	@param string text to treat
	@param object replacements
	@param integer count (if pural)

	@return boolean true if succeed, false else
	###
	s: (text, replacements, count) ->
		(local lang(), text, replacements, count).replace(/'/g, '’')
	,
	###
	Return current display locale

	@return string locale identifier
	###
	lang: ->
		"fr"
	,
	###
	Return HTML from Jade code
	@param string Jade input code

	@return string HTML rendered code
	###
	jd: (code) ->
		jadeRender = require('jade').render
		jadeRender(code)
	,
	###
	Return a HTML hidden tag that contains a named value
	@param string data name
	@param mixed data value

	@return string HTML div containing the data ("Error (see conole)" if an error occured)
	###
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
	###
	Append a variable to a response to use it in the view
	@param Response HTTP response to be appened
	@param string data name
	@param mixed data value

	@return void
	###
	shareData: (res, name, value) ->
		if typeof(value) is 'undefined'
			extend res.locals, name
		else
			res.locals[name] = value
		null
	,
	###
	Generate an asset URL (style, script, image, etc.) and append a version cache
	to avoid to have to clear the browser cache
	@param string file name
	@param string file directory
	@param string file primary extension

	@return assert URL
	###
	assetUrl: (file, directory, extension, keepExtension) ->
		if config.env.development
			version = fs.statSync('public/' + directory + '/' + file + '.' + extension).mtime.getTime()
		else
			version = config.wornet.version
		unless keepExtension
			extension = directory
		'/' + directory + '/' + file + '.' + extension + '?' + version
	,
	###
	Generate an style URL (automaticaly compiled with stylus)
	"login" > "/css/login.css?123"
	@param string file name

	@return assert URL
	###
	style: (file) ->
		assetUrl file, 'css', 'styl'
	,
	###
	Generate an script URL (automaticaly compiled with stylus)
	"login" > "/js/login.js?123"
	@param string file name

	@return assert URL
	###
	script: (file) ->
		assetUrl file, 'js', 'coffee'

	###
	Generate an PNG URL
	"login" > "/img/login.png?123"
	@param string file name

	@return assert URL
	###
	png: (file) ->
		assetUrl file, 'img', 'png', true

	###
	Generate an JPEG URL
	"login" > "/img/login.jpg?123"
	@param string file name

	@return assert URL
	###
	jpg: (file) ->
		assetUrl file, 'img', 'jpg', true

	###
	Generate an GIF URL
	"login" > "/img/login.gif?123"
	@param string file name

	@return assert URL
	###
	gif: (file) ->
		assetUrl file, 'img', 'gif', true