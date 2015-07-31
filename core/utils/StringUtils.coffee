StringUtils =
	toSearchRegExp: ->
		letters =
			a: 'âàäã'
			e: 'éèêë'
			c: 'ç'
			i: 'îïì'
			u: 'ùûü'
			o: 'ôöòõ'
			y: 'ÿ'
			n: 'ñ'
		query = @toLowerCase()
		for letter, list of letters
			list = '[' + letter + list + ']'
			query = query.replace (new RegExp list, 'gi'), list
		pattern = '(' + query.replace(/\s+/g, '|') + ')'
		new RegExp pattern, 'gi'

	contains: (needle) ->
		if typeof needle is 'string'
			@indexOf(needle) isnt -1
		else
			needle.test @

	startWith: (needle) ->
		@indexOf(needle) is 0

	endWith: (needle) ->
		@length > needle.length and @substr(-needle.length) is needle

	ucFirst: ->
		if @length
			@[0].toUpperCase() + @.substring 1

safeExtend String.prototype, StringUtils

module.exports = StringUtils
