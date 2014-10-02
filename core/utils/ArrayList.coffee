'use strict'
###
Extend Array prototype
###

getKeys = (keys, value = null) ->
	if typeof keys isnt 'object'
		key = keys
		keys = {}
		keys[key] = value
	keys

objectMatch = (obj, keys) ->
	if typeof obj is 'object'
		for key, val of keys 
			if typeof obj[key] is 'undefined' or obj[key] isnt val
				return true
	false

ArrayList =
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
	values: ->
		list = []
		@each ->
			list.push @
		list
	length: ->
		count = 0
		@each ->
			count++
		count

safeExtend Array.prototype, ArrayList
safeExtend Object.prototype, ArrayList

module.exports = ArrayList
