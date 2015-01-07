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
					false
				else
					true
			result

	each: (callback) ->
		if @ instanceof Array
			for obj, i in @
				if false is callback.call obj, i, obj
					return false
		else
			for k, obj of @
				if false is callback.call obj, k, obj
					return false
		true

	findOne: (keys, value = null) ->
		keys = getKeys keys, value
		result = null
		@each ->
			if objectMatch @, keys
				result = @
				return false
		result

	has: (keys, value = null) ->
		@findOne(keys, value) isnt null

	find: (keys, value = null) ->
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
			true
		list

	columns: (keys = null, preserveKeys = true) ->
		@values keys, preserveKeys

	column: (key) ->
		list = []
		@each ->
			list.push @[key]
		list

	merge: (values) ->
		if @ instanceof Array
			Array.prototype.push.apply @, values
		else
			extend @, values

	getLength: ->
		if @ instanceof Array
			@length
		else
			Object.keys(@).length

safeExtend Array.prototype, ArrayList
safeExtend Object.prototype, ArrayList

module.exports = ArrayList
