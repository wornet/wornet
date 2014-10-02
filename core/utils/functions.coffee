'use strict'

module.exports =
	###
	Resolve object get from template (passed in JSON)
	Restore date object converted to strings previously (by JSON stringification)
	@param mixed value that can contains Date objects stringified

	@return mixed value with stringified Date objectes restored
	###
	objectResolve: (value) ->

		key = 'resolvedCTBSWSydrqSuW2QyzUGMBTshU9SCJn5p'

		# First, convert the date and put the "resolved" key to do not reconvert
		enter = (value) ->
			switch typeof(value)
				when 'object'
					unless value[key]
						for v, i in value
							value[i] = enter value[i]
						value[key] = true
				when 'string'
					if /^[0-9-]+T[0-9:.]+Z$/.test value
						date = new Date value
						if date.isValid()
							value = date
			value

		# Then, remove all the "resolved" keys
		leave = (value) ->
			if typeof(value) is 'object' and value[key]
				delete value[key]
				for v, i in value
					value[i] = leave value[i]
			value

		leave enter value
	###
	Return an ID generated from the stack strace
	@return string hexadecimal md5 id
	###
	codeId: ->
		sha1(new Error().stack)
	###
	Get a cached mixed value
	@param string key for cached value in memcached store engine
	@param function to pass the result
	###
	memGet: (key, done) ->
		mem.get key, (err, result) ->
			if !err and result is false
				err = 'not found'
			else
				try
					result = objectResolve JSON.parse result
				catch e
					result = null
					err = 'json: ' + e
			done err, result
	###
	Set a cached mixed value
	@param string key for cached value in memcached store engine
	@param int time to keep the value in cache before calculate it again (seconds)
	@param mixed value
	@param function to pass the result
	###
	memSet: (key, value, lifetime, done) ->
		try
			value = JSON.stringify value
			mem.set key, value, lifetime, done
		catch e
			done 'json: ' + e
	###
	Cache a value
	@param string key for cached value in memcached store engine
	@param int time to keep the value in cache before calculate it again (seconds)
	@param function to execute to calculate value when it's not in cache
	@param function to pass the result
	###
	cache: (key, lifetime, calculate, done) ->
		if typeof(key) is 'function'
			done = lifetime
			calculate = key
			key = codeId()
			lifetime = 0
		else if typeof(lifetime) is 'function'
			done = calculate
			calculate = lifetime
			lifetime = 0
		else
			lifetime = if lifetime instanceof Date
				Math.round((time() - time(lifetime)) / 1000)
			else
				intval lifetime
		if lifetime < 1
			lifetime = config.wornet.cache.defaultLifetime
		if config.wornet.cache.enabled
			memGet key, (err, result) ->
				if err or result is false
					calculate (value) ->
						if value is false
							console.warn "[memcached] cannot store a false value"
							console.trace()
						done value, false
						memSet key, value, lifetime, (err) ->
							if err
								console.warn "[memcached] " + err
								console.trace()
				else
					done result, true
				null
		else
			calculate (value) ->
				done value, false
		null
	###
	Compress JS code
	@param string intial code

	@return string compressed code
	###
	uglifyJs: (code) ->
		jsp = require("uglify-js").parser
		pro = require("uglify-js").uglify
		ast = jsp.parse('try{' + code.replace(/^['"]use strict['"];/g, '') + '}catch(e){console.warn(e);}')
		ast = pro.ast_mangle(ast)
		ast = pro.ast_squeeze(ast)
		pro.gen_code(ast)

	###
	Get files contents, proceed callback of each content and concat all
	@param string intial code

	@return string compressed code
	###
	concatCallback: (content, lst, proceed, end, options) ->
		proceed = proceed || ((s) -> s)
		options = options || {}
		i = options.i || 0
		ie = options.ie || 0
		if i >= lst.length
			end content
		else
			file = lst[i]
			# Internet Explorer condition
			if typeof(file) is 'object'
				if file[0] is 'non-ie'
					file = (if ie then false else file[1])
				else
					version = 1
					symbol = file[0].replace /if\s*([^\s]*)\s*IE\s+([0-9\.]+)/g, (m, s, v)->
						version = intval v
						s
					switch symbol
						when 'gt'
							file = (if ie > version then file[1] else false)
						when 'gte'
							file = (if ie >= version then file[1] else false)
						when 'lt'
							file = (if ie < version then file[1] else false)
						when 'lte'
							file = (if ie <= version then file[1] else false)
						else
							file = (if ie is version then file[1] else false)
			done = ->
				concatCallback content, lst, proceed, end,
					i: i + 1
					ie: ie
			if file
				pathWithoutParams = file
				if file.indexOf('?') isnt -1
					path = file.replace /^([^\?]+)\?.*$/g, (m, start) ->
						pathWithoutParams = start
						__dirname + '/../../.build' + start
				else if file.charAt(0) is '/' and file.charAt(1) isnt '/'
					path = __dirname + '/../../public' + file
				else
					path = file
				fs.readFile path, (err, data) ->
					if err
						if err.code is 'ENOENT'
							require('http').get
								host: '127.0.0.1'
								port: config.port
								path: pathWithoutParams
							, (res) ->
								if ([0, 200]).indexOf res.statusCode is -1
									data = ''
									res.on 'error', (err) ->
										console.warn err
										done()
									res.on 'data', (chunk) ->
										data += chunk
									res.on 'end', ->
										content += proceed(data + '') + '\n'
										done()
								else
									console.warn pathWithoutParams + ' : Error ' + res.statusCode
									done()

						else
							console.warn err
							done()
					else
						content += proceed(data + '') + '\n'
						done()
			else
				done()

	###
	Do extend but hide the property/method to forbbid enumerate on it
	###
	safeExtend: (obj, props) ->
		Object.keys(props).forEach (key) ->
			if (props.hasOwnProperty key) and (typeof obj[key] is 'undefined')
				Object.defineProperty obj, key,
					value: props[key]
					writable: true
					configurable: true

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
			console.log Date.log()
			console.trace()
			console.log '=========================='

	###
	Return current timestamp (milliseconds sicne 1/1/1970)
	@param Date if you specify a date, the time will be extracted from it, else current timestamp is returned

	@return int current timestamp or timestamp from the given date
	###
	time: (date = new Date) ->
		date.getTime()

	###
	Return a Date object
	@param int if you specify a timestamp (in milliseconds), the date will be generated from it, else a new Date object is returned

	@return Date date from the given timestamp or actual date
	###
	date: (time = null) ->
		date = new Date
		if time isnt null
			date.setTime time
		date

	###
	Return a sha1 hased string
	@param string the string to hash
	@param string a salt can be added

	@return string sha1
	###
	sha1: (str, salt = null) ->
		if salt is null
			salt = config.wornet.secret
		crypto.createHmac('sha1', salt).update(str).digest('hex')

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

	###
	Return string value or "" if not able to convert
	@param mixed value to convert

	@return string value
	###
	strval: (str) ->
		str + ''

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

	###
	Return value if it's an array, else return an array containing the value
	@param mixed value

	@return Array list
	###
	arrayval: (val) ->
		if val instanceof Array
			val
		else
			[val]

	###
	@alias arrayval
	###
	list: (val) ->
		arrayval val

	###
	Return a regex string from RegExpString object get with the specified method (trim if any)
	This can be used in a pattern attribute (HTML5)
	@param string name of the pattern
	@param string|null method of the RegExpString class to use (trim if any)

	@return string matching regular expression
	###
	pattern: (name, method = 'trim') ->
		RegExpString[method] name

	###
	Return a regex from RegExpString object get with the specified method (trim if any)
	This can be used in .match, .replace etc. in controllers
	@param string name of the pattern
	@param string|null method of the RegExpString class to use (trim if any)

	@return RegExp matching regular expression
	###
	regex: (name, method = 'is') ->
		RegExp[method] name

	###
	Remove spaces at begen and end of a given string
	@param string text that can contains spaces

	@return string text without spaces
	###
	trim: (str) ->
		str.replace(/^\s+/g, '').replace(/\s+$/g, '')

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

	###
	Update user attributes
	@param HTTPRequest|User user model or request containing a user
	@param object update key-value list of updated attributes
	@param callback executed when everything is done
	###
	updateUser: (user, update, done) ->
		unless user instanceof User
			user = user.user
		for key, val of update
			user[key] = val
		User.update _id: user._id, update, multi: false, (updateErr) ->
			done updateErr

	###
	Get a user from an object
	@param Object list of attributes
	@return User user with given attributes
	###
	objectToUser: (object = {}, u = null) ->
		if typeof(object) is 'object'
			if object instanceof User
				u = object
			else
				u = new User
				extend u, object
		u

	###
	Add an uploaded photo to user album
	@param HTTPRequest request containing files object (uploaded)
	@param integer album number (0 = profile photo)
	@param callback executed when everything is done
	###
	addPhoto: (req, album, done) ->
		Photo.create
			user: req.user.id
			name: req.files.photo.name
			album: album
		, (createErr, photo) ->
			if createErr
				done createErr
			else
				id = photo.id
				photoDirectory = __dirname + '/../../public/img/photo/'
				dst = photoDirectory + id + '.jpg'
				copy req.files.photo.path, dst
				sizes = [50, 90, 200]
				pending = sizes.length
				for size in sizes
					thumb = photoDirectory + size + 'x' + id + '.jpg'
					imagemagick.resize
						srcPath: req.files.photo.path
						dstPath: thumb
						strip : false,
						width : size,
						height : size + "^",
						customArgs: [
							"-gravity", "center"
							"-extent", size + "x" + size
						]
					, (resizeErr) ->
						if resizeErr
							done resizeErr
						else unless --pending
							updateUser req, photoId: id, done

	###
	Return a string in lower case
	@param string text in any case

	@return string text in lower case
	###
	strtolower: (str) ->
		str.toLowerCase()

	###
	Return a string in upper case
	@param string text in any case

	@return string text in upper case
	###
	strtoupper: (str) ->
		str.toUpperCase()

	###
	Return a string with first character in upper case
	@param string text in any case

	@return string text with first character in upper case
	###
	ucfirst: (str) ->
		str.charAt(0).toUpperCase() + str.substr(1)

	###
	Shorthand to exec a callback after a delay specified in milliseconds
	@param integer delay
	@param function callback

	@return integer timeout identifier (could be passed to a clearTimeout function)
	###
	delay: (ms, cb) ->
		setTimeout cb, ms

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
						(
							value.length is 0 ||
							typeof(value.length) is 'function' && value.length() is 0
						)
					) || (
						typeof(value.length) is 'undefined' &&
						typeof(JSON) is 'object' &&
						typeof(JSON.stringify) is 'function' &&
						JSON.stringify(value) is '{}'
					)
				)
			)
		)

	###
	Copy a file in a new path
	@param string source file
	@param string destination file

	@return boolean true if succeed, false else
	###
	copy: (from, to) ->
		fs.createReadStream(from).pipe(fs.createWriteStream(to))

	###
	Applying replacemens and pluralization in a given text
	@param string text to treat
	@param object replacements
	@param integer count (if pural)

	@return boolean true if succeed, false else
	###
	s: (text, replacements, count) ->
		(local lang(), text, replacements, count).replace(/'/g, '’')

	###
	Return current display locale

	@return string locale identifier
	###
	lang: ->
		"fr"

	###
	Return HTML from Jade code
	@param string Jade input code

	@return string HTML rendered code
	###
	jd: (code) ->
		jadeRender = require('jade').render
		jadeRender(code)

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

	###
	Generate an asset URL (style, script, image, etc.) and append a version cache
	to avoid to have to clear the browser cache
	@param string file name
	@param string file directory
	@param string file primary extension

	@return assert URL
	###
	assetUrl: (file, directory, extension, keepExtension, limit) ->
		# assetUrl use sync functions
		# we can do it here because assetUrl is only in use in development
		# but always prefer async functions to accelerate page load
		# and defer treatments
		version = config.wornet.version
		if /https?:\/\//g.test file
			file + '.' + extension + '?' + version
		else 
			source = 'public/' + directory + '/' + file + '.' + extension
			unless keepExtension
				extension = directory
			if config.env.development || limit
				stat = fs.statSync(source)
			if limit && limit > stat.size
				switch extension
					when 'js' then type = 'text/javascript'
					when 'js' then type = 'text/style'
					else type = 'image/' + extension.replace('jpg', 'jpeg')
				"data:" + type + ";base64," + fs.readFileSync(source).toString('base64')
			else
				if config.env.development
					version = stat.mtime.getTime()
				'/' + directory + '/' + file + '.' + extension + '?' + version

	###
	Generate an style URL (automaticaly compiled with stylus)
	"login" > "/css/login.css?123"
	@param string file name

	@return assert URL
	###
	style: (file) ->
		assetUrl file, 'css', 'styl'

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
	png: (file, limit) ->
		assetUrl file, 'img', 'png', true, limit

	###
	Generate an JPEG URL
	"login" > "/img/login.jpg?123"
	@param string file name

	@return assert URL
	###
	jpg: (file, limit) ->
		assetUrl file, 'img', 'jpg', true, limit

	###
	Generate an GIF URL
	"login" > "/img/login.gif?123"
	@param string file name

	@return assert URL
	###
	gif: (file, limit) ->
		assetUrl file, 'img', 'gif', true, limit

	###
	Prepend server for big images if specified in config.json
	@param string file name

	@return assert URL
	###
	bigImg: (file) ->
		config.wornet.bigImagesServer + file