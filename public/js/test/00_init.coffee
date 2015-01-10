jasmine.DEFAULT_TIMEOUT_INTERVAL = 100000
iframeLoad = (url, done) ->
	$('<iframe>')
		.appendTo 'body'
		.prop 'src', url
		.load done
	return