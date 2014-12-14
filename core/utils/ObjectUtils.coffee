'use strict'

###
Extend Object prototype
###

ObjectUtils =

	# override: (key, fct) ->

	updateById: (id, update, done) ->
		@findById(id).update update, done || (err) ->
			if err
				throw err

safeExtend Object.prototype, ObjectUtils

module.exports = ObjectUtils
