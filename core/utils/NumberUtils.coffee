multiples =

	# time
	second: 1000
	seconds: 1000
	minute: 60 * 1000
	minutes: 60 * 1000
	hour: 60 * 60 * 1000
	hours: 60 * 60 * 1000

	# date
	day: 24 * 60 * 60 * 1000
	days: 24 * 60 * 60 * 1000
	week: 7 * 24 * 60 * 60 * 1000
	weeks: 7 * 24 * 60 * 60 * 1000
	month: 30 * 24 * 60 * 60 * 1000
	months: 30 * 24 * 60 * 60 * 1000
	year: 365 * 24 * 60 * 60 * 1000
	years: 365 * 24 * 60 * 60 * 1000

multiples.each (key) ->
	value = @
	Number.prototype.__defineGetter__ key, ->
		@ * value

module.exports = multiples
