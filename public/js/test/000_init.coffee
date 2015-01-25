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

$.fn.extend
	findInFrame: (selector) ->
		result = @[0].contentWindow.$ selector
		if result.length is 0
			expect(selector).toBe 'found'
		result
	complete: (selector, data) ->
		if typeof(data) is 'undefined'
			data = selector
			selector = ''
		else
			selector += ' '
		for name, value of data
			elt = @findInFrame selector + '[name="' + name + '"]'
			if elt.attr 'ng-model'
				scope = elt.scope()
				obj = scope
				model = elt.attr('ng-model').split /\./g
				i = 0
				while i < model.length - 1
					obj = obj[model[i++]] ||= {}
				obj[model[i]] = if elt.attr('type') is 'date'
						new Date value
					else
						value
				scope.$apply()
			if value is true or value is false
				elt.prop 'checked', value
			else
				elt.val value
		@
	page: (done, reject) ->
		reject ||= (err) ->
			throw err || new Error 'Loading error'
		@off 'load error'
		.load ->
			@contentWindow.$.expr[':'].icontains = $.expr[':'].icontains
			@contentWindow.$.fn.extend.complete = $.fn.extend.complete
			done.apply @
		.error reject
	form: (selector, done, reject) ->
		if typeof selector is 'function'
			reject = done
			done = selector
			selector = 'form'
		@findInFrame(selector).submit()
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