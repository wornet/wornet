'use strict'

module.exports =
	###
	Instanciate a new standart error

	@return PublicError
	###
	standartError: ->
		new PublicError s("Navré, la dernière action a échouée. Veuillez réessayer ultérieurement.")
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
						for i, v of value
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
				for i, v of value
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
	Unlink file and handle errors
	###
	unlink: ->
		params = Array.prototype.slice.call arguments
		params[1] ||= (err) ->
			if err
				warn err
		try
			fs.unlink.apply fs, params
		catch err
			warn err
	###
	Compress JS code
	@param string intial code

	@return string compressed code
	###
	uglifyJs: (code) ->
		output = code
		if code.indexOf('// Generated by CoffeeScript') is 0
			output = code
				.replace /\n/g, '\n\n'
				.replace /^\/\/[^\n]*\n/g, ''
				.replace /([^\\:"'])\/\/[^\n]*\n/g, '$1'
				.replace /(\n|\s{2,})/g, ''
				.replace /\/\*(.*?)\*\//g, ''
		else if code.indexOf('angular.') is -1
			jsp = require("uglify-js").parser
			pro = require("uglify-js").uglify
			try
				ast = jsp.parse code, config.wornet.uglify || {}
				ast = pro.ast_mangle ast
				ast = pro.ast_squeeze ast
				minifiedCode = pro.gen_code ast
				unless config.wornet.uglify.minifyOnRate and minifiedCode.length / code.length > config.wornet.uglify.minRate
					output = minifiedCode
			catch e
		output

	###
	Get files contents, proceed callback of each content and concat all
	@param string intial code

	@return string compressed code
	###
	concatCallback: (content, lst, proceed, end, options) ->
		proceed ||= ((s) -> s)
		options ||= {}
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
			concat = (data) ->
				content += proceed(strval(data))
				if content.charAt(content.length - 1) isnt ';'
					content += ';'
				content += '\n'
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
								if ([0, 200]).contains res.statusCode
									data = ''
									res.on 'error', (err) ->
										console.warn err
										done()
									res.on 'data', (chunk) ->
										data += chunk
									res.on 'end', ->
										if data.indexOf('<!DOCTYPE html>') is 0
											warn path + ' return HTML'
										else
											concat data
										done()
								else
									warn pathWithoutParams + ' : Error ' + res.statusCode
									done()

						else
							warn err
							done()
					else
						concat data
						done()
			else
				done()

	###
	Do extend but hide the property/method to forbbid enumerate on it
	###
	safeExtend: (obj) ->
		for i in [1..arguments.length-1]
			props = arguments[i]
			Object.keys(props).forEach (key) ->
				if (props.hasOwnProperty key) and (typeof obj[key] is 'undefined')
					Object.defineProperty obj, key,
						value: props[key]
						writable: true
						configurable: true


	###
	Get listed notifications

	@param notifications array
	@param friend asks map

	@return ordered notifications list
	###
	getNotifications: (notifications, coreNotifications, friendAsks = {}, friends = []) ->
		notifications = notifications.map (n) ->
			if typeof(n[0]) is 'string'
				n[0] = new Date n[0]
		friendAskIds = []
		for id, friend of friendAsks
			if friend.askedTo and ! friendAskIds.contains(id) and ! friends.has(hashedId: friend.hashedId)
				friendAskIds.push id
				notifications.push [id, friend, id]
		for notice in coreNotifications
			unless notifications.has((v) -> v[1] is notice.content)
				notifications.push [notice.id, notice.content]
		notifications.sort (a, b) ->
			unless a[0] instanceof Date
				d = Date.fromId a[0]
				if d.isValid()
					a[0] = d
				else
					warn new Error a[0] + " n'est pas de type Date"
			unless b[0] instanceof Date
				d = Date.fromId b[0]
				if d.isValid()
					b[0] = d
				else
					warn new Error b[0] + " n'est pas de type Date"
			if a[0] < b[0]
				-1
			else if a[0] > b[0]
				1
			else
				0
		notifications

	###
	Return a stack trace as string or parse a given stack trace
	@param string|Error error (optionnal)

	@return string
	###
	trace: (message) ->
		if message is undefined
			throw new Error 'Undefined trace'
		message += '\n' + (message.stack || (new Error).stack.replace /^Error:/g, 'Stack trace:')
		if config.debug and config.debug.skipJsFiles
			message = message.replace /[\t ]*at[^\n]+\.js(:[0-9]+)*\)?[\t ]*[\n\r]/g, ''
		message

	###
	Display a message or variable and stack trace if on a development environment
	@param mixed message or vairbale to print in console log

	@return void
	###
	log: (message, method = 'log') ->
		# if ! config.env or config.env.development
		console['log'] '=========================='
		console[method] message
		console['log'] '--------------------------'
		Date.log()
		console['log'] trace message
		console['log'] '=========================='
	###
	Display a warning message and stack trace
	@param mixed message or vairbale to print in console warn

	@return void
	###
	warn: (message, gitlab = true) ->
		if gitlab
			GitlabPackage.error message
		log message, 'warn'
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
	Reverses caracters in a string
	@param string input
	@return string reversed input
	###
	strrev: (input) ->
		output = ""
		for i in [input.length - 1 .. 0]
			output += input.charAt i
		output

	###
	Crypt a string with a Cesar key
	@param string input string to crypt
	@param int factor (tow opposite factors with the same key match)
	@param string Cesar key

	@return string crypted key
	###
	cesar: (input, factor = 1, key = null) ->
		if key is null
			if config?
				key = config.wornet.hexSecret
			else
				key = "d6f7b887265debac5120de672873"
		output = ""
		for i in [0 .. input.length - 1]
			output += ((Math.abs(factor) * 16 + parseInt(input.charAt(i), 16) + factor * parseInt(key.charAt(i % key.length), 16)) % 16).toString(16)
		output

	###
	Crypt a string with a Cesar key and 1 factor
	@param string input string to crypt
	@param string Cesar key

	@return string crypted key
	###
	cesarLeft: (input, key = null) ->
		cesar strrev(input), 1, key

	###
	Crypt a string with a Cesar key and -1 factor
	@param string input string to crypt
	@param string Cesar key

	@return string crypted key
	###
	cesarRight: (input, key = null) ->
		strrev(cesar input, -1, key)

	###
	Return string value or "" if not able to convert
	@param mixed value to convert

	@return string value
	###
	strval: (str) ->
		str + ''

	###
	Compare two values as strings
	@param mixed value convertable to string
	@param mixed value convertable to string

	@return boolean true if strings converted from values are equal
	###
	equals: (a, b) ->
		a + '' is b + ''

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
	trim: (str, charlist = '\\s') ->
		begin = new RegExp '^' + charlist + '+', 'g'
		end = new RegExp charlist + '+$', 'g'
		strval str
			.replace begin, ''
			.replace end, ''

	###
	Convert a date form input into a Date object
	@param string input date

	@return Date output same date
	###
	inputDate: (str) ->
		new Date strval(str).replace /^([0-9]+)\/([0-9]+)\/([0-9]+)$/g, '$3-$2-$1'

	###
	Iterate a value with a callback if value has an `each` method
	@param value to be iterated
	@param function callback to iterate on value

	@return true if the array was able to iterate, false else
	###
	each: (value, callback) ->
		if value and value.each and typeof value.each is 'function'
			value.each callback
			true
		else
			false

	###
	Exec remove on all model/condition pairs passed in arguments
	@param Array... [model, conndition] pairs
	@param function callback executed when all parallel removes ended

	@return void
	###
	parallelRemove: ->
		done = (err) ->
			if err
				throw err
		params = Array.prototype.filter.call arguments, (arg) ->
			if arg instanceof Array
				true
			else
				if typeof arg is 'function'
					done = arg
				else
					throw new Error 'Invalid argument'
				false
		errors = []
		count = params.length
		next = (errors) ->
			err = if errors.length > 0
				new Error errors.join('\n')
			else
				null
			done err
		params.each ->
			model = @[0]
			condition = @[1]
			# Model.remove was not able to be used here since it does not trigger the `remove` hook
			model.find condition, (err, objs) ->
				if err
					errors.push err
				each objs, ->
					count++
					@remove (err) ->
						if err
							errors.push err
						unless --count
							next errors
				unless --count
					next errors
		return

	###
	Load model if it is not already. In any case, return it
	@param string model name
	@param Schema schema for generate the model
				  (if any given, the file is used name = "myModel", a MyModelSchema.coffee file
				  must exist in models/ directory)

	@return Model asked model
	###
	model: (name, schema) ->
		requireSchema = (name) ->
			require __dirname + '/../../models/' + ucfirst(name) + 'Schema'
		if global[name]? || global[name + 'Model']?
			global[name] || global[name + 'Model']
		else
			schema ||= requireSchema name
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
		# for key, val of update
		# 	user[key] = val
		try
			User.updateById user._id, update, (err, user) ->
				unless err
					extend user, update
				done err, user
		catch err
			done err

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
	Convert known custom/english error to translatable human error
	@param mixed error
	@return string humanazied error
	###
	humanError: (err) ->
		if err and err.errors
			ul = '<ul>'
			err.errors.each ->
				ul += '<li>' + (
						switch strval @
							when 'invalid first name'
								s("Prénom invalide")
							when 'invalid last name'
								s("Nom invalide")
							when 'invalid birth date'
								s("Date de naissance invalide")
							when 'invalid phone number'
								s("Numéro de téléphone invalide")
							when 'too long biography'
								s("La zone créative dépasse la taille limite (" + config.wornet.limits.biographyLength + " caractères)")
							else
								@
					) + '</li>'
			ul += '</ul>'
			err = new PublicError ul
		err

	###
	Add an uploaded photo to user album
	@param HTTPRequest request containing files object (uploaded)
	@param ObjectId albumId id (0 = profile photo)
	@param callback executed when everything is done
	###
	addPhoto: (req, image, albumId, done) ->
		notProfilePhoto = (albumId and albumId isnt "0")
		next = (createdAlbum = null) ->
			Photo.create
				user: req.user.id
				name: image.name
				album: albumId
			, (createErr, photo) ->
				if createErr
					done createErr, createdAlbum, photo
				else
					id = photo.id
					PhotoPackage.add req, id
					photoDirectory = __dirname + '/../../public/img/photo/'
					dst = photoDirectory + id + '.jpg'
					copy image.path, dst
					sizes = config.wornet.thumbSizes
					pending = sizes.length
					for size in sizes
						thumb = photoDirectory + size + 'x' + id + '.jpg'
						imagemagick.resize
							srcPath: image.path
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
								done resizeErr, createdAlbum, photo
							else unless --pending
								done null, createdAlbum, photo
		if notProfilePhoto
			next()
		else
			defaultName = s("Photos de profil")
			albumProperties =
				user: req.user.id
				name: defaultName
			Album.findOne albumProperties, (err, album) ->
				if album
					albumId = album.id
					next album
				else
					Album.create albumProperties, (err, album) ->
						if err
							done err
						else
							albumId = album.id
							next album

	###
	Return a string in lower case
	@param string text in any case

	@return string text in lower case
	###
	strtolower: (str) ->
		str += ''
		str.toLowerCase()

	###
	Return a string in upper case
	@param string text in any case

	@return string text in upper case
	###
	strtoupper: (str) ->
		str += ''
		str.toUpperCase()

	###
	Return a string with first character in upper case
	@param string text in any case

	@return string text with first character in upper case
	###
	ucfirst: (str) ->
		str += ''
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
	Execute a task at a given interval
	@param integer delay
	@param function callback

	@return integer interval identifier (could be passed to a clearInterval function)
	###
	regularTask: (ms, cb) ->
		do cb
		setInterval cb, ms

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
							typeof(value.length) is 'function' && value.getLength() is 0
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
	Append colon with locale language rule
	@param string text to complete

	@return string complete text
	###
	colon: (text) ->
		text + s(" : ") 

	###
	Return current display locale

	@return string locale identifier
	###
	lang: ->
		'fr'

	###
	Return HTML from Jade code
	@param string Jade input code

	@return string HTML rendered code
	###
	jd: (code) ->
		require('jade').render code

	###
	Return HTML from Markdown code
	@param string Markdown input code

	@return string HTML rendered code
	###
	md: (code) ->
		require('node-markdown').Markdown code.toString()

	###
	Return HTML from Markdown file
	@param string Markdown input file path

	@return string HTML rendered code
	###
	mdFile: (file) ->
		md fs.readFileSync __dirname + '/../../views/' + file

	###
	Return HTML from Markdown file
	@param string Markdown input file path

	@return string HTML rendered code
	###
	mdLangFile: (file) ->
		mdFile file + '/' + lang() + '.md'

	###
	Return HTML from Markdown file
	@param string Markdown input file path

	@return string HTML rendered code
	###
	mdIncludeLangFile: (file) ->
		mdLangFile 'includes/' + file

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
	Base 64 encode
	@param string

	@return string encoded
	###
	btoa: (a) ->
		a.toString 'base64'

	###
	Base 64 encode
	@param string

	@return string encoded
	###
	atob: (a) ->
		b = new Buffer a, 'base64'
		b.toString()

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
			source = 'public' + profilePhotoUrl '/' + directory + '/' + file + '.' + extension
			unless keepExtension
				extension = directory
			if config.env.development || limit
				stat = fs.statSync source
			if limit && limit > stat.size
				switch extension
					when 'js' then type = 'text/javascript'
					when 'js' then type = 'text/style'
					else type = 'image/' + extension.replace 'jpg', 'jpeg'
				"data:" + type + ";base64," + btoa fs.readFileSync source
			else
				if config.env.development
					version = stat.mtime.getTime()
				file = file.replace /^\//g, ''
				appendVersion = ''
				unless file.indexOf('photo/') is 0
					appendVersion = '?' + version
				(config.wornet.staticServer || '') + '/' + directory + '/' + file + '.' + extension + appendVersion

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

	###
	Convert profile photo URL to real photo path
	@param string url

	@return string rewrited url
	###
	profilePhotoUrl: (url) ->
		url.replace /^(\/img\/photo\/[^\/]+)\/[^\/]+\.jpg$/g, '$1.jpg'

	###
	Wrap text with quotes and escape quotes and backslashes within it
	@param string text

	@return string quoted text
	###
	quoteString: (str) ->
		'"' + str.replace(/\\/g, '\\\\').replace(/"/g, '\\"') + '"'
