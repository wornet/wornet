# Send HTTP GET, POST, PUT and DELETE request through AJAX
Ajax =
	###
	Send a GET AJAX request

	@param string request URL
	@param object|function jQuery AJAX settings object or success callback function
	@param string HTTP method to emulate (DELETE, PUT, HEAD)
	@param defaultType GET or POST

	@return XHR object (+ jQuery extra stuff)
	###
	get: (url, settings, _method, defaultType = "GET") ->
		# If the second parameter is a function, we use it as success callback
		if typeof(settings) is 'function'
			settings =
				success: settings
		settings.type = settings.type || defaultType
		# Get JSON response by default
		settings.dataType = settings.dataType || "json"
		settings.data = settings.data || {}
		# Append CSRF token (needed for security)
		settings.data._csrf = settings.data._csrf || $('head meta[name="_csrf"]').attr 'content'
		# If method isnt GET or POST, it must be emulated
		if _method?
			# Set method in data POST parameters
			settings.data._method = _method
		$.ajax url, settings

	###
	Send a POST AJAX request

	@param string request URL
	@param object|function jQuery AJAX settings object or success callback function
	@param string HTTP method to emulate (DELETE, PUT, HEAD)

	@return XHR object (+ jQuery extra stuff)
	###
	post: (url, settings, _method) ->
		@get url, settings, _method, "POST"

	###
	Send a PUT AJAX request

	@param string request URL
	@param object|function jQuery AJAX settings object or success callback function

	@return XHR object (+ jQuery extra stuff)
	###
	put: (url, settings) ->
		@post url, settings, "PUT"

	###
	Send a DELETE AJAX request

	@param string request URL
	@param object|function jQuery AJAX settings object or success callback function

	@return XHR object (+ jQuery extra stuff)
	###
	delete: (url, settings) ->
		@post url, settings, "DELETE"


###
Crud can send request to its member URL
###
class Crud
	constructor: (url = '/') ->
		@url = url

	url: (url = '/') ->
		new Crud @url + url

	get: (settings, _method, defaultType) ->
		Ajax.get @url, settings, _method, defaultType

	post: (settings, _method) ->
		Ajax.post @url, settings, _method

	put: (settings) ->
		Ajax.put @url, settings

	delete: (settings) ->
		Ajax.delete @url, settings