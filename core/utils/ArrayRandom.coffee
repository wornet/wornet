'use strict'
###
Extend Array prototype
###

RandomArray =
	###
	Pick random values from an array
	@param int count : number of values
	@return array list of values if count is specified
	@return mixed a unique value if count isn't specified
	###
	pick: (count = 0) ->
		count = intval count
		if count < 1
			@[Math.floor(Math.random() * @length)]
		else
			(@pick() for [1..count])

	###
	Pick a random value and remove it from an array
	@param int count : number of values
	@return array list of values if count is specified
	@return mixed a unique value if count isn't specified
	###
	pickAndShift: (count = 0) ->
		count = intval count
		if count < 1
			index = Math.floor(Math.random() * @length)
			value = @[index]
			others = @filter (val, i) ->
				i isnt index
			for [1..@length]
				@shift()
			arr = @
			others.forEach (val) ->
				arr.push val
			value
		else
			(@pickAndShift() for [1..count])

	###
	Pick random values from an array (but not twice the same)
	@param int count : number of values
	@return array list of values if count is specified
	@return mixed a unique value if count isn't specified
	###
	pickUnique: (count = 0) ->
		count = intval count
		if count < 1
			@pick()
		else if count > @length
			@pickAndShift count
		else
			@.slice()

safeExtend Array.prototype, RandomArray

module.exports = RandomArray
