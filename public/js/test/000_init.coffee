jasmine.DEFAULT_TIMEOUT_INTERVAL = 60 * 1000

if window.sessionStorage
	sessionStorage.clear()
if window.localStorage
	localStorage.clear()

$.expr[':'].icontains = (a, i, m) ->
	$(a).text().toUpperCase().indexOf(m[3].toUpperCase()) >= 0

delay = (ms, cb) ->
	if typeof ms is 'function'
		cb = ms
		ms = 50
	setTimeout cb, ms

Function.prototype.after = (ms) ->
	fct = @
	->
		ctx = @
		delay ms, ->
			fct.apply ctx

class Sequence
	_state: 'PENDING'
	_index: 0
	_fcts: []
	_catch: (err) ->
		throw err
	_do: ->
		if @_index < @_fcts.length
			params = Array.prototype.slice.call arguments
			fulfill = @_do
			reject = ->
				@_state = 'FAILED'
				@_catch.apply @, arguments
			params.unshift fulfill.bind(@), reject.bind(@)
			try
				@_fcts[@_index++].apply @, params
			catch e
				console['warn'] e
				reject.bind(@) e
		else
			@_state = 'SUCCEEDED'
	constructor: (fcts) ->
		if typeof(fcts) is 'function'
			fcts = [fcts]
		@_fcts = fcts
		delay 1, @_do.bind @
	state: ->
		@_state
	catch: (fct) ->
		@_catch = fct
		@
	then: (fct) ->
		@_fcts.push fct
		@

sequence = (fct) ->
	new Sequence [fct]

setValue = (elt, value) ->
	if elt.attr 'ng-model'
		scope = elt.scope()
		obj = scope
		model = elt.attr('ng-model').split /\./g
		i = 0
		while i < model.length - 1
			obj = obj[model[i++]] ||= {}
		obj[model[i]] =
			if elt.attr('type') is 'date'
				new Date value
			else
				value
		scope.$apply()
	if value is true or value is false
		elt.prop 'checked', value
	else
		elt.val value

$.fn.extend
	set: (value) ->
		setValue @, value
		@
	findInFrame: (selector) ->
		result = @[0].contentWindow.$ selector
		if result.length is 0
			throw new Error selector + ' not found'
		result
	complete: (selector, data) ->
		if typeof(data) is 'undefined'
			data = selector
			selector = ''
		else
			selector += ' '
		for name, value of data
			setValue @findInFrame(selector + '[name="' + name + '"]'), value
		@
	page: (done, reject) ->
		reject ||= (err) ->
			throw err || new Error 'Loading error'
		loadJQuery = ->
			w = @contentWindow
			w$ = w.$
			w$.expr[':'].icontains = $.expr[':'].icontains
			$.each ['complete', 'set'], ->
				w$.fn[@] = $.fn[@]
		@off 'load error'
		.load ->
			loadJQuery.apply @
			done.apply @
		.error ->
			loadJQuery.apply @
			reject.apply @
	form: (selector, done, reject) ->
		if typeof selector is 'function'
			reject = done
			done = selector
			selector = 'form'
		@findInFrame(selector).submit()
		window._ctx = @
		@page done, reject
	src: (url, done, reject) ->
		@prop 'src', url
		.page done, reject
	link: (selector, done, reject) ->
		@findInFrame(selector)[0].click()
		@page done, reject

_shouldExists = (w, selector, msg, toBe = true) ->
	msg ||= selector + ' must exist'
	expect(w.exists selector).toBe toBe, msg
	return
_shouldNotExists = (w, selector, msg) ->
	msg ||= selector + ' must not exist'
	_shouldExists w, selector, msg, false
	return
iframeLoad = (url, done, reject) ->
	$('<iframe>')
		.appendTo 'body'
		.src url, done, reject
	return
url = (w) ->
	'/' + (w.location.href.replace /https?:\/\/[^\/]+\/?/g, '')
testWith = (url, next) ->
	beforeEach (done) ->
		iframeLoad url, ->
			$tester = $ @
			w = @contentWindow
			next $tester, w, _shouldExists.bind(w, w), _shouldNotExists.bind(w, w)
			w.$ ->
				do done
				return
			return
		return
	return