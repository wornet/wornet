'use strict'

###
Extend Object (used like Map) and Array prototype
###

getKeys = (keys, value = null) ->
	if typeof keys isnt 'object'
		key = keys
		keys = {}
		keys[key] = value
	keys

differ = (a, b) ->
	if a instanceof mongoose.Types.ObjectId
		a = strval a
	if b instanceof mongoose.Types.ObjectId
		b = strval b
	a isnt b

objectMatch = (obj, keys) ->
	if typeof obj is 'object'
		for key, val of keys
			if typeof obj[key] is 'undefined' or differ obj[key], val
				return false
	true

global.EACH_BREAK = 'EACH_BREAK'

ArrayList =
	copy: ->
		if @ instanceof Array
			@slice()
		else
			extend {}, @

	contains: (needle, compare) ->
		if typeof @indexOf is 'function' and ! compare
			@indexOf(needle) isnt -1
		else
			compare ||= (val, needle) ->
				val is needle
			result = false
			@each ->
				if compare @, needle
					result = true
					EACH_BREAK
			result

	each: (callback) ->
		if @ instanceof Array
			for obj, i in @
				if EACH_BREAK is callback.call obj, i, obj
					return false
		else
			for k, obj of @
				if EACH_BREAK is callback.call obj, k, obj
					return false
		true

	findOne: (keys, value = null) ->
		keys = getKeys keys, value
		result = null
		@each ->
			if objectMatch @, keys
				result = @
				EACH_BREAK
		result

	matchFilter: (callback) ->
		if @filter
			@filter.apply @, arguments
		else
			result = {}
			for k, v of @
				if callback v, k, @
					result[k] = v
			result

	has: (keys, value = null) ->
		if typeof keys is 'function'
			try
				@matchFilter(keys).getLength() > 0
			catch e
				warn e
		else
			@findOne(keys, value) isnt null

	findMany: (keys, value = null) ->
		keys = getKeys keys, value
		list = []
		@each ->
			if objectMatch @, keys
				list.push @
		list

	values: (keys = null, preserveKeys = false) ->
		list = (if preserveKeys then {} else [])
		keys ||= Object.keys @
		self = @
		keys.each ->
			if preserveKeys
				list[@] = self[@]
			else
				list.push self[@]
		list

	columns: (keys = null, preserveKeys = true) ->
		@values keys, preserveKeys

	column: (key) ->
		list = []
		@each ->
			list.push @[key]
		list

	add: ->
		for val in arguments
			unless @contains val
				@push val
		@

	merge: (values, push = 'push') ->
		if @ instanceof Array
			@[push].apply @, arrayval values
		else if values
			extend @, values
		@

	with: (values) ->
		result = @copy()
		result.merge values
		result

	getLength: ->
		if @ instanceof Array
			@length
		else
			Object.keys(@).length

	isFirst: (index) ->
		if @ instanceof Array
			-1 is @slice(0, index).indexOf @[index]
		else
			throw new Error 'isFirst is not implemented for objects'

	unique: (keys = null) ->
		if keys is null
			mapper = JSON.stringify
		else if typeof keys is 'function'
			mapper = keys
		else
			if typeof keys isnt 'object'
				keys = [keys]
			mapper = (val) ->
				JSON.stringify val.values keys
		if @ instanceof Array
			index = @map mapper
			@filter (val, i) ->
				index.isFirst i
		else
			index = []
			@each (k) ->
				index.push mapper @
			result = {}
			pos = 0
			@each (k) ->
				if index.isFirst pos
					result[k] = @
				pos++
			result

	###
	Return lastest elements of an array
	@param number of elements to get
	@return array lastest elements
	###
	lastest: (count) ->
		if @ instanceof Array
			res = if count < @length
				@slice @length - count
			else
				@slice()
			res.reverse()
			res
		else
			@columns Object.keys(@).lastest count


safeExtend Array::, ArrayList
safeExtend Object::, ArrayList

# Aliases
# each
# 	findMany: 'find'
# , (alias, func) ->
# 	Array::[alias] = Array::[func]
# 	Object::[alias] = Object::[func]

module.exports = ArrayList
