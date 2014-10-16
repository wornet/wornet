StringUtils =
	contains: (needle) ->
		if typeof needle is 'string'
			@indexOf(needle) isnt -1
		else
			needle.test @

	startWith: (needle) ->
		@indexOf(needle) is 0

	endWith: (needle) ->
		@length > needle.length and @substr(-needle.length) is needle

safeExtend String.prototype, StringUtils

module.exports = StringUtils
